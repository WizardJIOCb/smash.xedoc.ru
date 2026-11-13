'use strict';
(() => {
  const screen = document.getElementById('loading-screen');
  const phase = document.getElementById('loading-phase');
  const percent = document.getElementById('loading-percent');
  const progress = document.getElementById('loading-progress');
  const fill = document.getElementById('loading-fill');
  let value = 0;
  const update = (next, label) => {
    value = Math.max(value, Math.min(100, next));
    fill.style.transform = `scaleX(${value / 100})`;
    percent.textContent = Math.floor(value) + '%';
    progress.setAttribute('aria-valuenow', String(Math.floor(value)));
    if (label) phase.textContent = label;
    document.body.setAttribute('data-game-loading', JSON.stringify({percent: value, phase: phase.textContent}));
  };
  document.getElementById('retry').onclick = () => location.reload();
  window.smashLoading = {
    progress: (ratio, cached) => update(ratio * 90, ratio >= 1 ? 'Будим Лося…' : cached ? 'Возвращаемся в сохранённый двор…' : 'Загружаем двор…'),
    ready: () => {
      update(100, 'Двор открыт');
      screen.classList.add('finished');
      setTimeout(() => { screen.hidden = true; }, 550);
      document.getElementById('canvas').focus();
    },
    error: error => {
      phase.textContent = 'Не получилось открыть двор';
      document.getElementById('loading-hint').textContent = error.message || 'Проверь соединение и попробуй ещё раз.';
      document.getElementById('retry').hidden = false;
      screen.classList.remove('finished');
      screen.hidden = false;
    }
  };
})();
