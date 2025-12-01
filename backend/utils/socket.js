const socketIO = require('socket.io');

let io;

module.exports = {
    init: (server) => {
        io = socketIO(server, {
            cors: {
                origin: process.env.FRONTEND_URL,
                methods: ['GET', 'POST']
            }
        });

        io.on('connection', (socket) => {
            console.log('مستخدم جديد متصل');

            socket.on('join', (userId) => {
                socket.join(`user_${userId}`);
            });

            socket.on('disconnect', () => {
                console.log('مستخدم غير متصل');
            });
        });

        return io;
    },
    getIO: () => {
        if (!io) {
            throw new Error('Socket.io غير مهيأ');
        }
        return io;
    }
};