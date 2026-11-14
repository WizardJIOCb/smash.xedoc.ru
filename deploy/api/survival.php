<?php
declare(strict_types=1);

// Casual client-reported results, isolated from campaign records.
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
$input = [];
if ($method === 'POST') {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    if ($origin !== '' && $origin !== 'https://smash.xedoc.ru') {
        respond(403, ['error' => 'origin']);
    }
    if (strtolower(trim(explode(';', $_SERVER['CONTENT_TYPE'] ?? '')[0])) !== 'application/json') {
        respond(415, ['error' => 'content_type']);
    }
    $raw = file_get_contents('php://input', false, null, 0, 4097);
    if ($raw === false || strlen($raw) > 4096 || (int)($_SERVER['CONTENT_LENGTH'] ?? 0) > 4096) {
        respond(413, ['error' => 'size']);
    }
    try {
        $input = json_decode($raw, true, 16, JSON_THROW_ON_ERROR);
    } catch (JsonException) {
        respond(400, ['error' => 'json']);
    }
    if (!is_array($input) || array_is_list($input)) {
        respond(400, ['error' => 'payload']);
    }
}
$board = $method === 'GET' ? ($_GET['board'] ?? 'solo') : ($input['board'] ?? null);
if (!in_array($board, ['solo', 'coop'], true)) {
    respond(422, ['error' => 'board']);
}
$operation = $method === 'GET' ? 'list' : ($input['op'] ?? '');
if (!in_array($operation, ['list', 'start', 'finish'], true) || ($method === 'POST' && $operation === 'list')) {
    respond(400, ['error' => 'operation']);
}
if ($method === 'POST') {
    $players = $input['players'] ?? null;
    if (!is_int($players) || ($board === 'solo' ? $players !== 1 : ($players < 2 || $players > 16))) {
        respond(422, ['error' => 'players']);
    }
}

$directory = getenv('SMASH_STATE_DIR') ?: '/var/lib/smash-xedoc';
if (!is_dir($directory) || !is_writable($directory)) {
    respond(503, ['error' => 'storage_unavailable']);
}
$handle = fopen($directory . '/survival.json', 'c+');
if ($handle === false || !flock($handle, LOCK_EX)) {
    respond(503, ['error' => 'storage_busy']);
}
$rawState = stream_get_contents($handle);
$state = $rawState === '' ? ['version' => 1, 'runs' => [], 'scores' => []] : json_decode($rawState, true);
if (!is_array($state) || ($state['version'] ?? null) !== 1
    || !is_array($state['runs'] ?? null) || !is_array($state['scores'] ?? null)) {
    respond(503, ['error' => 'storage_invalid']);
}
$now = microtime(true);
$state['runs'] = array_filter($state['runs'], fn(array $run): bool => $now - $run['started'] <= 86400);
$boardRows = function() use (&$state, $board): array {
    return array_values(array_filter($state['scores'], fn(array $row): bool => $row['board'] === $board));
};

if ($operation === 'list') {
    $response = ['board' => $board, 'scores' => array_slice($boardRows(), 0, 10)];
} elseif ($operation === 'start') {
    // Retain used tokens until expiry: replay protection and rate accounting share the same lifetime.
    $ip = hash('sha256', ($_SERVER['REMOTE_ADDR'] ?? '') . '|smash-survival-v1');
    $recent = array_filter($state['runs'], fn(array $run): bool => $run['ip'] === $ip && $now - $run['started'] < 60);
    if (count($recent) >= 8) {
        header('Retry-After: 60');
        respond(429, ['error' => 'rate_limit']);
    }
    $token = bin2hex(random_bytes(24));
    $state['runs'][hash('sha256', $token)] = [
        'started' => $now, 'ip' => $ip, 'board' => $board, 'players' => $players,
    ];
    $response = ['token' => $token, 'board' => $board, 'players' => $players];
} else {
    $token = $input['token'] ?? null;
    if (!is_string($token) || !preg_match('/^[0-9a-f]{48}$/D', $token)) {
        respond(400, ['error' => 'token']);
    }
    $key = hash('sha256', $token);
    $run = $state['runs'][$key] ?? null;
    if ($run === null || isset($run['used'])) {
        respond(409, ['error' => 'run_unavailable']);
    }
    $name = $input['name'] ?? null;
    $wave = $input['wave'] ?? null;
    $kills = $input['kills'] ?? null;
    $seconds = $input['seconds'] ?? null;
    if ($run['board'] !== $board || $run['players'] !== $players
        || !is_string($name) || !is_int($wave) || !is_int($kills)
        || (!is_int($seconds) && !is_float($seconds)) || !is_finite((float)$seconds)
        || $wave < 1 || $wave > 10000 || $kills < $wave - 1 || $kills > 1000000
        || $seconds < 5 || $seconds > 86400 || $now - $run['started'] + 3 < $seconds) {
        respond(422, ['error' => 'result_invalid']);
    }
    $name = trim(preg_replace('/[^\p{L}\p{N} ._\-]/u', '', $name) ?? '');
    preg_match('/^.{0,20}/us', $name === '' ? 'Лось' : $name, $nameMatch);
    $state['scores'][] = [
        'name' => $nameMatch[0], 'board' => $board, 'players' => $players,
        'wave' => $wave, 'kills' => $kills, 'seconds' => round((float)$seconds, 2), 'date' => gmdate('Y-m-d'),
    ];
    usort($state['scores'], fn(array $a, array $b): int => ($b['wave'] <=> $a['wave'])
        ?: ($b['kills'] <=> $a['kills']) ?: ($a['seconds'] <=> $b['seconds']));
    $kept = [];
    foreach (['solo', 'coop'] as $group) {
        $kept = array_merge($kept, array_slice(array_values(array_filter($state['scores'],
            fn(array $row): bool => $row['board'] === $group)), 0, 50));
    }
    $state['scores'] = $kept;
    $state['runs'][$key]['used'] = true;
    $response = ['saved' => true, 'board' => $board, 'scores' => array_slice($boardRows(), 0, 10)];
}

rewind($handle);
$encoded = json_encode($state, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
if (fwrite($handle, $encoded) !== strlen($encoded) || !ftruncate($handle, strlen($encoded)) || !fflush($handle)) {
    respond(503, ['error' => 'storage_write']);
}
flock($handle, LOCK_UN);
fclose($handle);
respond(200, $response);
