const PORT = 8080;
const http = require('http');
const socketIO = require('socket.io');

const httpServer = http.createServer((request, response) => {
  response.writeHead(200, { 'Content-Type': 'text/plain' });
  response.end('notion-teleprompter-p2p-server');
}).listen(PORT);

const io = socketIO(httpServer, {
  cors: {
    origin: '*'
  },
});

io.on('connection', socket => {
  socket.on('message', message => {
    io.emit('message', message);
  });
});
