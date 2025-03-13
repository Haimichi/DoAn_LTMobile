const Review = require('../models/reviewModels');

exports.createReview = async (req, res) => {
  try {
    const user_id = req.userId;
    
    const reviewData = {
      user_id: user_id,
      book_id: req.body.book_id,
      review: req.body.comment,
      rating: req.body.rating
    };

    console.log('Creating review with data:', reviewData);
    const review = await Review.create(reviewData);
    
    res.status(200).json({
      success: true,
      data: review
    });
  } catch (error) {
    console.error('Error in createReview:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

exports.getReviewsByBookId = async (req, res) => {
  try {
    const bookId = req.params.bookId;
    console.log('Getting reviews for bookId:', bookId);
    
    const reviews = await Review.getByBookId(bookId);
    
    const mappedReviews = reviews.map(review => ({
      review_id: review.review_id,
      user_id: review.user_id,
      book_id: review.book_id,
      comment: review.comment,
      rating: review.rating,
      created_at: review.created_at,
      full_name: review.full_name || 'Ẩn danh'
    }));

    res.status(200).json({
      success: true,
      data: mappedReviews
    });
  } catch (error) {
    console.error('Error in getReviewsByBookId:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
