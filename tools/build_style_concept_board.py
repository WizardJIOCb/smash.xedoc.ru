"""Assemble the current original visual proposal with its liked anchors."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
board = root / ".studioigor/boards/style-r2"
board.mkdir(parents=True, exist_ok=True)
concepts = [
    ("los-character-v1.png", "Лось: силуэт, характер и три позы. Концепт, анимации и рига пока нет."),
    ("courtyard-alive-v1.png", "Живой район: корни и провода, тёплые окна, глубина и читаемая линия боя. Сгенерированный концепт, не игровой кадр."),
    ("courtyard-quarantine-v1.png", "Тот же район под карантином: гаснут окна, включаются красные лучи, меняются дождь, туман и дальний фон. Сгенерированный концепт."),
]
media = [{"src": "../../../art/concepts/" + f, "caption": caption,
          "generated": True, "credit": "Original concept · image_gen",
          "source": "../../../art/concepts/prompts-v1.md"} for f, caption in concepts]
anchors = []
anchor_notes = {
    "steam-9be07f14.jpg": "Твоя отметка: нравится. Берём мягкие крупные формы, живописную глубину и холодную дымку между планами.",
    "steam-79c9bc53.jpg": "Твоя отметка: нравится. Берём тёплые окна, провода, городской масштаб и свет в глубине улицы.",
    "steam-b608cfbe.jpg": "Твоя отметка: нравится. Берём объёмные мультяшные формы, характер поз и разделение ближнего и дальнего планов.",
}
for set_name, filename in [
    ("forest-server", "steam-9be07f14.jpg"),
    ("concrete-rain", "steam-79c9bc53.jpg"),
    ("paper-punk", "steam-b608cfbe.jpg"),
]:
    data = json.loads((root / ".studioigor/refs" / set_name / "sources.json").read_text(encoding="utf-8"))
    item = next(i for i in data["items"] if i["file"] == filename)
    anchors.append({"src": "../../refs/" + set_name + "/" + filename,
                    "caption": anchor_notes[filename], "source": item["page"],
                    "credit": item["credit"], "license": item["license"], "generated": False})
spec = {
    "title": "Лось — первый образ и мир",
    "subtitle": "Предложение по твоим отметкам. Картинки ниже — концепты; игра и скелетная анимация ещё не собраны.",
    "question": "Подходят Лось и мир? Отметь кадры и напиши правки, затем отправь отзыв. Можно ответить прямо в чат.",
    "mode": "none",
    "options": [
        {"id": "living-city", "title": "Заросший город с тёплыми окнами", "text": "Живописная глубина и мягкий свет; смешной тяжёлый Лось в спортивке. Преображение карантином видно на одной и той же локации.",
         "palette": ["#132630", "#386264", "#718068", "#e2b36e", "#e7d3ac", "#e44a42"], "media": media},
        {"id": "anchors", "title": "Твои отметки, на которые я опирался", "text": "Лес и глубина, городской свет, объёмный мультяшный персонаж. Это референсы чужих работ; в игру они не попадут.", "media": anchors},
    ],
}
spec_path = board / "board.json"
spec_path.write_text(json.dumps(spec, ensure_ascii=False, indent=2), encoding="utf-8")
skill_script = Path.home() / ".codex/skills/studioigor/scripts/board.py"
subprocess.run([sys.executable, "-X", "utf8", str(skill_script), "build", str(spec_path)], check=True)
index = board / "index.html"
page = index.read_text(encoding="utf-8")
for before, after in [
    ("General comment: what to take, what to drop, what's missing…", "Что нравится? Что изменить в герое или мире?"),
    (">Send</button>", ">Отправить отзыв</button>"),
    ("'Like');", "'Нравится');"), ("'Not it');", "'Мимо');"),
    ("'generated'", "'концепт ИИ'"),
    ("'Comment on option \\\"'", "'Комментарий: \\\"'"),
    ("'Selected: '", "'Выбрано: '"),
    ("' · liked: '", "' · нравится: '"), ("' · not it: '", "' · мимо: '"),
    ("'source'", "'источник'"),
    ("'← → browse · Esc close · L like · D not it'", "'← → листать · Esc закрыть · L нравится · D мимо'"),
    ("'Sent'", "'Отзыв сохранён'"),
    ("'The agent got the feedback. You can go back to the terminal.'", "'Можно вернуться в чат.'"),
]:
    page = page.replace(before, after)
index.write_text(page, encoding="utf-8")
