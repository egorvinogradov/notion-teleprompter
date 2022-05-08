const PORT = 8080;
const http = require('http');
const socketIO = require('socket.io');

const httpServer = http.createServer((request, response) => {
  response.writeHead(200, {
    'Content-Type': 'text/plain',
    'Access-Control-Allow-Origin': '*',
  });
  response.end('notion-teleprompter-sync-server');
}).listen(PORT);

const io = socketIO(httpServer, {
  transports: ['polling'],
  cors: {
    origin: '*'
  },
});

io.on('connection', socket => {
  socket.on('message', message => {
    io.emit('message', message);
  });
});
