const conversationSchema = new mongoose.Schema({
    participants: [{
        type: mongoose.Schema.ObjectId,
        ref: 'User'
    }],
    lastMessage: {
        type: mongoose.Schema.ObjectId,
        ref: 'Message'
    },
    property: {
        type: mongoose.Schema.ObjectId,
        ref: 'Property'
    },
    type: {
        type: String,
        enum: ['عقار', 'صيانة', 'عام'],
        default: 'عام'
    }
}, {
    timestamps: true
});