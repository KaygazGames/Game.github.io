#!/bin/bash
# Bloxd.io benzeri bir multiplayer oyun sunucusu için otomatik kurulum betiği

# Proje dizinini oluştur ve içine gir
echo "Proje dizini oluşturuluyor: bloxd-clone"
mkdir bloxd-clone
cd bloxd-clone || exit

# npm projesini başlat
echo "npm projesi başlatılıyor..."
npm init -y

# Gerekli paketleri yükle
echo "Express ve Socket.io paketleri yükleniyor..."
npm install express socket.io

# server.js dosyasını oluştur
echo "server.js dosyası oluşturuluyor..."
cat << 'EOF' > server.js
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// public klasöründeki statik dosyaları sun
app.use(express.static('public'));

let players = {};

io.on('connection', (socket) => {
  console.log(`Player connected: ${socket.id}`);

  // Yeni oyuncuyu ekle, başlangıç konumu ve rastgele renk
  players[socket.id] = {
    x: 400,
    y: 300,
    color: '#' + Math.floor(Math.random() * 16777215).toString(16)
  };

  // Tüm oyuncuları güncelle
  io.emit('players', players);

  // Oyuncu hareket verisini al ve güncelle
  socket.on('move', (data) => {
    if (players[socket.id]) {
      players[socket.id].x = data.x;
      players[socket.id].y = data.y;
      io.emit('players', players);
    }
  });

  // Bağlantı kesilince oyuncuyu sil
  socket.on('disconnect', () => {
    console.log(`Player disconnected: ${socket.id}`);
    delete players[socket.id];
    io.emit('players', players);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

# public dizinini oluştur ve index.html dosyasını oluştur
echo "public dizini ve index.html dosyası oluşturuluyor..."
mkdir public
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <title>Bloxd.io Clone - Multiplayer</title>
  <style>
    body { margin: 0; padding: 0; background: #222; }
    canvas { background: #006400; display: block; margin: auto; }
  </style>
</head>
<body>
  <canvas id="gameCanvas" width="800" height="600"></canvas>
  <script src="/socket.io/socket.io.js"></script>
  <script>
    const socket = io();
    const canvas = document.getElementById('gameCanvas');
    const ctx = canvas.getContext('2d');
    let players = {};

    // Yerel oyuncu pozisyonunu takip etmek için başlangıç konumu
    let playerPosition = { x: 400, y: 300 };

    // Sunucudan oyuncu verilerini al
    socket.on('players', (data) => {
      players = data;
    });

    // Tuş dinleyicisi ile oyuncu hareketi
    document.addEventListener('keydown', (event) => {
      const speed = 5;
      if (event.key === 'ArrowUp') playerPosition.y -= speed;
      if (event.key === 'ArrowDown') playerPosition.y += speed;
      if (event.key === 'ArrowLeft') playerPosition.x -= speed;
      if (event.key === 'ArrowRight') playerPosition.x += speed;
      
      // Canvas sınırları içinde kalmasını sağla
      playerPosition.x = Math.max(15, Math.min(canvas.width - 15, playerPosition.x));
      playerPosition.y = Math.max(15, Math.min(canvas.height - 15, playerPosition.y));
      
      socket.emit('move', playerPosition);
    });

    // Basit oyun döngüsü: tüm oyuncuları çiz
    function gameLoop() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Ortada bir çizgi çiz (örnek amaçlı)
      ctx.strokeStyle = 'white';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(canvas.width / 2, 0);
      ctx.lineTo(canvas.width / 2, canvas.height);
      ctx.stroke();

      // Tüm oyuncuları çiz
      for (let id in players) {
        const p = players[id];
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, 15, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = 'white';
        ctx.font = '12px Arial';
        ctx.fillText(id, p.x - 20, p.y - 20);
      }
      requestAnimationFrame(gameLoop);
    }
    gameLoop();
  </script>
</body>
</html>
EOF

echo "Kurulum tamamlandı! Sunucuyu başlatmak için 'node server.js' komutunu çalıştırın."
