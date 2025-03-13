class ApiStrings {
  static const String hostNameUrl = 'http://10.0.2.2:5000';
  // static const String hostNameUrl = 'http://192.168.1.17:5555';

  // Auth routes
  static const String signUpUrl = '/api/auth/register';
  static const String signInUrl = '/api/auth/login';
  static const String isTokenValid = '/api/auth/isTokenValid';
  static const String authMiddleware = '/api/auth/';

  // Product routes
  static const String getProductsUrl = '/admin/get_products';
  static const String getSpecialOffersUrl = '/api/get_special_offers';

  // Order routes
  static const String generateCustomerPinUrl = '/api/create_pin';
  static const String placeOrderUrl = '/api/place_order';
  static const String getMyOrdersUrl = '/api/get_my_orders';

  // User routes
  static const String updateAvatarUrl = '/api/user/avatar';
  static const String getUserInfoUrl = '/api/user/info';
  static const String updateProfileUrl = '/api/user/update-profile';
  static const String getUserInfoForAddressUrl = '/api/user/get-user-info';
  static const String getUsersUrl = '/api/user';
  static const String deleteUserUrl = '/api/user';

  // Address routes
  static const String getAddressesUrl = '/api/address/get-addresses';
  static const String addAddressUrl = '/api/address';
  static const String getDefaultAddressUrl = '/api/address/default';

  // Book routes
  static const String getBooksUrl = '/api/books';
  static const String addBookUrl = '/api/books';
  static const String updateBookUrl = '/api/books';
  static const String deleteBookUrl = '/api/books';

  // Category routes
  static const String getCategoriesUrl = '/api/categories';
  static const String getCategoryByIdUrl = '/api/categories/';

  // Review routes
  static const String reviewsUrl = '/api/reviews';
  static const String getBookReviewsUrl = '/api/reviews/book';
}
