<?php
declare(strict_types=1);

// Shared casual leaderboard. Game credentials and storage stay outside the web root.
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

function respond(int $code, array $value): never {
    http_response_code($code);
    echo json_encode($value, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if (!in_array($method, ['GET', 'POST'], true)) {
    header('Allow: GET, POST');
    respond(405, ['error' => 'method']);
}
if ($method === 'POST') {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    if ($origin !== '' && $origin !== 'https://smash.xedoc.ru') {
        respond(403, ['error' => 'origin']);
    }
    if (!str_starts_with(strtolower($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')) {
        respond(415, ['error' => 'content_type']);
    }
    $raw = file_get_contents('php://input', false, null, 0, 4097);
    if ($raw === false || strlen($raw) > 4096) {
        respond(413, ['error' => 'size']);
    }
    try {
        $input = json_decode($raw, true, 16, JSON_THROW_ON_ERROR);
    } catch (JsonException) {
        respond(400, ['error' => 'json']);
    }
    if (!is_array($input)) {
        respond(400, ['error' => 'payload']);
    }
} else {
    $input = [];
}

$directory = getenv('SMASH_STATE_DIR') ?: '/var/lib/smash-xedoc';
if (!is_dir($directory) || !is_writable($directory)) {
    respond(503, ['error' => 'storage_unavailable']);
}
$handle = fopen($directory . '/scores.json', 'c+');
if ($handle === false || !flock($handle, LOCK_EX)) {
    respond(503, ['error' => 'storage_busy']);
}
$rawState = stream_get_contents($handle);
$state = $rawState === '' ? ['runs' => [], 'scores' => []] : json_decode($rawState, true);
if (!is_array($state) || !isset($state['runs'], $state['scores'])) {
    respond(503, ['error' => 'storage_invalid']);
}
$now = microtime(true);
$state['runs'] = array_filter($state['runs'], fn(array $run): bool => $now - $run['started'] < 3600);
$operation = $method === 'GET' ? 'list' : ($input['op'] ?? '');
$response = [];
$chapter = filter_var($input['chapter'] ?? $_GET['chapter'] ?? 1, FILTER_VALIDATE_INT);
if (!in_array($chapter, [1, 2, 3], true)) { respond(422, ['error' => 'chapter']); }
$chapterRows = function() use (&$state, $chapter): array { return array_values(array_filter($state['scores'], fn(array $row): bool => ($row['chapter'] ?? 1) === $chapter)); };

if ($operation === 'list') {
    $response = ['scores' => array_slice($chapterRows(), 0, 10)];
} elseif ($operation === 'start') {
    // A one-use run token and a short rate limit curb accidental replay/spam.
    // Client gameplay is not an authoritative anti-cheat system.
    $ip = hash('sha256', ($_SERVER['REMOTE_ADDR'] ?? '') . '|smash-casual-v1');
    $recent = array_filter($state['runs'], fn(array $run): bool => $run['ip'] === $ip && $now - $run['started'] < 60);
    if (count($recent) >= 8) {
        header('Retry-After: 60');
        respond(429, ['error' => 'rate_limit']);
    }
    $token = bin2hex(random_bytes(24));
    $state['runs'][hash('sha256', $token)] = ['started' => $now, 'ip' => $ip, 'chapter' => $chapter];
    $response = ['token' => $token];
} elseif ($operation === 'finish') {
    $token = $input['token'] ?? null;
    if (!is_string($token) || !preg_match('/^[0-9a-f]{48}$/D', $token)) {
        respond(400, ['error' => 'token']);
    }
    $key = hash('sha256', $token);
    if (!isset($state['runs'][$key]) || isset($state['runs'][$key]['used'])) {
        respond(409, ['error' => 'run_unavailable']);
    }
    $name = $input['name'] ?? '';
    $seconds = $input['seconds'] ?? null;
    $health = $input['health'] ?? null;
    $deaths = $input['deaths'] ?? null;
    if (!is_string($name) || !is_numeric($seconds) || !is_int($health) || !is_int($deaths)
        || ($state['runs'][$key]['chapter'] ?? 1) !== $chapter
        || ($input['kills'] ?? null) !== [1 => 5, 2 => 14, 3 => 12][$chapter]
        || ($input['relays'] ?? null) !== ($chapter === 1 ? 3 : 4)
        || $health < 0 || $health > 100 || $deaths < 0 || $deaths > 100
        || (float)$seconds < 5 || (float)$seconds > 3600
        || $now - $state['runs'][$key]['started'] + 3 < (float)$seconds) {
        respond(422, ['error' => 'result_invalid']);
    }
    $name = trim(preg_replace('/[^\p{L}\p{N} ._\-]/u', '', $name) ?? '');
    $name = mb_substr($name === '' ? 'Лось' : $name, 0, 20);
    $seconds = round((float)$seconds, 2);
    $score = max(0, 5000 + $health * 10 + max(0, 3000 - (int)floor($seconds * 10)) - $deaths * 200);
    $row = ['name' => $name, 'score' => $score, 'seconds' => $seconds,
        'health' => $health, 'date' => gmdate('Y-m-d'), 'chapter' => $chapter];
    $state['scores'][] = $row;
    usort($state['scores'], fn(array $a, array $b): int => ($b['score'] <=> $a['score']) ?: ($a['seconds'] <=> $b['seconds']));
    $kept = [];
    foreach ([1, 2, 3] as $group) {
        $kept = array_merge($kept, array_slice(array_values(array_filter($state['scores'],
            fn(array $row): bool => ($row['chapter'] ?? 1) === $group)), 0, 50));
    }
    $state['scores'] = $kept;
    $state['runs'][$key]['used'] = true;
    $response = ['saved' => true, 'scores' => array_slice($chapterRows(), 0, 10)];
} else {
    respond(400, ['error' => 'operation']);
}

rewind($handle);
$encoded = json_encode($state, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
if (fwrite($handle, $encoded) !== strlen($encoded)) {
    respond(503, ['error' => 'storage_write']);
}
ftruncate($handle, strlen($encoded));
fflush($handle);
flock($handle, LOCK_UN);
fclose($handle);
respond(200, $response);
