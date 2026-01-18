const mineflayer = require('mineflayer');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {
    host: '127.0.0.1',
    port: 25565,
    count: 10,
    prefix: 'bench',
    durationSeconds: 600,
    delayMs: 250,
  };
  for (let i = 0; i < args.length; i++) {
    const key = args[i];
    const value = args[i + 1];
    switch (key) {
      case '--host':
        out.host = value;
        i++;
        break;
      case '--port':
        out.port = Number(value);
        i++;
        break;
      case '--count':
        out.count = Number(value);
        i++;
        break;
      case '--prefix':
        out.prefix = value;
        i++;
        break;
      case '--duration':
        out.durationSeconds = Number(value);
        i++;
        break;
      case '--delay':
        out.delayMs = Number(value);
        i++;
        break;
      default:
        break;
    }
  }
  return out;
}

const config = parseArgs();
const bots = [];

function spawnBot(index) {
  const bot = mineflayer.createBot({
    host: config.host,
    port: config.port,
    username: `${config.prefix}${index}`,
  });
  bot.on('error', (err) => {
    console.error(`bot ${index} error`, err);
  });
  bot.on('kicked', (reason) => {
    console.error(`bot ${index} kicked`, reason);
  });
  bots.push(bot);
}

for (let i = 0; i < config.count; i++) {
  setTimeout(() => spawnBot(i + 1), i * config.delayMs);
}

const timeout = setTimeout(() => {
  for (const bot of bots) {
    bot.quit('benchmark complete');
  }
  process.exit(0);
}, config.durationSeconds * 1000);

process.on('SIGINT', () => {
  clearTimeout(timeout);
  for (const bot of bots) {
    bot.quit('interrupted');
  }
  process.exit(1);
});
