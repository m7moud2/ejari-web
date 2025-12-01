// models/Property.js

const mongoose = require('mongoose');
const slugify = require('slugify');

const propertySchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'الرجاء إدخال عنوان العقار'],
        trim: true,
        maxlength: [100, 'عنوان العقار يجب ألا يتجاوز 100 حرف']
    },
    slug: String,
    description: {
        type: String,
        required: [true, 'الرجاء إدخال وصف العقار']
    },
    type: {
        type: String,
        required: [true, 'الرجاء تحديد نوع العقار'],
        enum: ['apartment', 'villa', 'house', 'office', 'shop']
    },
    status: {
        type: String,
        enum: ['available', 'rented', 'maintenance'],
        default: 'available'
    },
    price: {
        type: Number,
        required: [true, 'الرجاء إدخال سعر العقار']
    },
    location: {
        address: {
            type: String,
            required: [true, 'الرجاء إدخال العنوان']
        },
        city: {
            type: String,
            required: [true, 'الرجاء إدخال المدينة']
        },
        coordinates: {
            type: {
                type: String,
                enum: ['Point'],
                default: 'Point'
            },
            coordinates: [Number]
        }
    },
    features: {
        bedrooms: Number,
        bathrooms: Number,
        area: Number,
        furnished: Boolean,
        airCondition: Boolean,
        parking: Boolean,
        elevator: Boolean
    },
    amenities: [{
        type: String
    }],
    images: [{
        type: String,
        required: [true, 'الرجاء إضافة صور للعقار']
    }],
    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    currentTenant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    ratings: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        rating: {
            type: Number,
            min: 1,
            max: 5
        },
        review: String,
        date: {
            type: Date,
            default: Date.now
        }
    }],
    averageRating: {
        type: Number,
        default: 0
    },
    maintenanceHistory: [{
        issue: String,
        description: String,
        status: {
            type: String,
            enum: ['pending', 'in-progress', 'completed'],
            default: 'pending'
        },
        reportedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        reportedAt: {
            type: Date,
            default: Date.now
        },
        completedAt: Date,
        cost: Number
    }],
    documents: [{
        type: {
            type: String,
            enum: ['contract', 'deed', 'other']
        },
        title: String,
        file: String,
        uploadedAt: {
            type: Date,
            default: Date.now
        }
    }],
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// إنشاء الslug قبل الحفظ
propertySchema.pre('save', function(next) {
    this.slug = slugify(this.title, { lower: true });
    next();
});

// فهرسة الموقع للبحث القريب
propertySchema.index({ 'location.coordinates': '2dsphere' });

// Virtual لعدد التقييمات
propertySchema.virtual('numberOfRatings').get(function() {
    return this.ratings.length;
});

// حساب متوسط التقييم
propertySchema.methods.calculateAverageRating = function() {
    const avg = this.ratings.reduce((acc, item) => item.rating + acc, 0) / 
                (this.ratings.length || 1);
    this.averageRating = Math.round(avg * 10) / 10;
    return this.averageRating;
};

module.exports = mongoose.model('Property', propertySchema);