
const mongoose = require('mongoose');

const connectDatabase = async () => {
    if (!process.env.MONGODB_URI) {
        throw new Error(
            'Chua cau hinh MONGODB_URI trong file .env'
        );
    }

    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Da ket noi MongoDB thanh cong!');

    // Chuyen doi du lieu trang thai cong viec cu
    const taskCollection = mongoose.connection.collection('tasks');

    // Cong viec da hoan thanh
    await taskCollection.updateMany(
        {
            status: { $exists: false },
            completed: true
        },
        {
            $set: { status: 'completed' },
            $unset: { completed: '' }
        }
    );

    // Cong viec chua hoan thanh hoac chua co trang thai
    await taskCollection.updateMany(
        {
            status: { $exists: false }
        },
        {
            $set: { status: 'not_started' },
            $unset: { completed: '' }
        }
    );

    // Xoa truong completed cu neu con ton tai
    await taskCollection.updateMany(
        {
            completed: { $exists: true }
        },
        {
            $unset: { completed: '' }
        }
    );

    console.log('Da chuyen doi trang thai cong viec cu thanh cong!');
};

module.exports = connectDatabase;
