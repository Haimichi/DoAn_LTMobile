import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/constants.dart';
import 'package:booky/models/PlaceOrderItem.dart';
import 'package:booky/utils/helper_method.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:booky/utils/api_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/screens/main_screens/cart_screen/cart_screen.dart';
import 'package:intl/intl.dart';
import 'package:booky/common/widgets/product_grid_tile.dart';
import 'dart:math' show min;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';

class AddToCartScreen extends StatefulWidget {
  static const String routeName = '/add_to_cart';

  const AddToCartScreen({super.key, required this.product});

  final product;

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  final SizedBox _sizedBox20 = const SizedBox(height: 20);
  final SizedBox _sizedBox10 = const SizedBox(height: 10);

  String firstHalf = '';
  String secondHalf = '';

  bool flag = true;

  // String selectedColor = '';
  // String selectSize = '';

  // List<String> shoeSizes = [];
  // List<String> shoeColor = [];

  int quantity = 1;

  final reviewController = TextEditingController();
  double userRating = 5.0;

  Map<String, dynamic> productRatings = {};
  double averageRating = 0.0;
  int totalReviews = 0;
  Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  bool showReviews = false;
  TextEditingController reviewNameController = TextEditingController();
  TextEditingController reviewContentController = TextEditingController();

  int reviewContentLength = 0;

  int maxQuantity = 1;

  int maxPurchasableQuantity = 999999;

  int _currentPreviewPage = 0;

  List<String> splitAndTrim(String inputString) {
    List<String> splitStrings = inputString.split(',');

    List<String> trimmedList =
        splitStrings.map((s) => s.trim().toLowerCase()).toList();

    // print('trimmedList -----------------> $trimmedList');

    return trimmedList;
  }

  List<Map<String, dynamic>> reviews = [];

  bool _isLoadingReviews = false;

  List<Map<String, dynamic>> relatedBooks = [];
  bool _isLoadingRelated = false;

  List<String> previewImages = [];

  FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    // print('widget.product -----------------------> ${widget.product}');

    if (widget.product['ratings'] != null) {
      productRatings = Map<String, dynamic>.from(widget.product['ratings']);
    }

    averageRating = widget.product['averageRating']?.toDouble() ?? 0.0;

    totalReviews = widget.product['totalReviews'] ?? 0;

    if (widget.product['productDescription'].length > 150) {
      firstHalf = widget.product['productDescription'].substring(0, 150);
      secondHalf = widget.product['productDescription']
          .substring(150, widget.product['productDescription'].length);
    } else {
      firstHalf = widget.product['productDescription'];
      secondHalf = "";
    }

    // shoeSizes = splitAndTrim(widget.product['productSizes']);
    // shoeColor = splitAndTrim(widget.product['productColors']);

    _getReviews();

    reviewContentController.addListener(() {
      setState(() {
        reviewContentLength = reviewContentController.text.length;
      });
    });

    fetchRelatedBooks();

    maxQuantity = int.parse(widget.product['quantity'] ?? '1');
    quantity = min(quantity, maxQuantity);

    maxPurchasableQuantity =
        widget.product['max_purchasable_quantity'] ?? 999999;

    if (widget.product['preview_images'] != null) {
      if (widget.product['preview_images'] is String) {
        String previewStr = widget.product['preview_images'].toString();
        try {
          previewImages = previewStr
              .replaceAll('"', '')
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) =>
                  e.startsWith('http') ? e : '${ApiStrings.hostNameUrl}$e')
              .toList();
        } catch (e) {
          print('Error parsing preview images: $e');
          previewImages = [];
        }
      } else if (widget.product['preview_images'] is List) {
        previewImages = List<String>.from(widget.product['preview_images'])
            .map(
                (e) => e.startsWith('http') ? e : '${ApiStrings.hostNameUrl}$e')
            .toList();
      }
    }
    print('Preview images after processing: $previewImages');
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _getReviews() async {
    if (_isLoadingReviews) return;

    try {
      _isLoadingReviews = true;
      final bookId = widget.product['bookId'] ?? widget.product['productId'];
      if (bookId == null) {
        throw Exception('Không tìm thấy ID sách');
      }

      final url =
          '${ApiStrings.hostNameUrl}${ApiStrings.getBookReviewsUrl}/$bookId';
      print('Getting reviews from URL: $url');

      final response = await http.get(Uri.parse(url));

      print('Get reviews response: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          reviews = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print('Error getting reviews: $e');
    } finally {
      _isLoadingReviews = false;
    }
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return Center(child: Text('Chưa có đánh giá nào'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewItem(
          review: review,
          onShowAll: () => _showReviewsDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CHI TIẾT SẢN PHẨM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.preview, color: Colors.white),
            onPressed: () => _showPreviewImages(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: size.height * 0.5,
              width: double.infinity,
              color: Colors.white,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: widget.product['productImages'].length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Image.network(
                              widget.product['productImages'][index],
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: _buildDots(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sizedBox20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.product['productName'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_outline_rounded),
                      ),
                    ],
                  ),
                  const Divider(),
                  _sizedBox20,
                  const Text(
                    'MÔ TẢ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    firstHalf + (flag ? "..." : secondHalf),
                  ),
                  InkWell(
                    child: Row(
                      children: [
                        Text(
                          flag ? "Xem thêm" : "Thu gọn",
                          style: const TextStyle(
                              color: AppConstants.kPrimaryColor1),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        flag = !flag;
                      });
                    },
                  ),
                  _buildPreviewButtons(),
                  _sizedBox20,
                  // Delivery estimation
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping_outlined),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dự kiến giao hàng',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _getEstimatedDeliveryDate(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Return policy
                  InkWell(
                    onTap: _showReturnPolicyDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_return_outlined),
                              SizedBox(width: 12),
                              Text(
                                'Đổi trả toàn quốc 30 ngày',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  // Quantity selection
                  // Container(
                  //   padding: EdgeInsets.symmetric(vertical: 12),
                  //   child: Row(
                  //     children: [
                  //       Text('Số lượng'),
                  //       const SizedBox(width: 20),
                  //       Stack(
                  //         children: [
                  //           Container(
                  //             width: 100,
                  //             height: 32,
                  //             decoration: BoxDecoration(
                  //               border: Border.all(color: Colors.black54),
                  //               borderRadius: BorderRadius.circular(6),
                  //             ),
                  //             child: Center(
                  //               child: Container(
                  //                 decoration: const BoxDecoration(
                  //                   color: AppConstants.kGrey2,
                  //                   border: Border(
                  //                     left: BorderSide(
                  //                         color: AppConstants.kGrey3),
                  //                     right: BorderSide(
                  //                         color: AppConstants.kGrey3),
                  //                   ),
                  //                 ),
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(
                  //                     left: 8,
                  //                     right: 8,
                  //                     top: 6,
                  //                     bottom: 6,
                  //                   ),
                  //                   child: Text(
                  //                     quantity.toString(),
                  //                     style: const TextStyle(
                  //                       fontSize: 14,
                  //                       color: Colors.black,
                  //                       fontWeight: FontWeight.bold,
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //           Positioned(
                  //             right: -5,
                  //             top: 0,
                  //             bottom: 0,
                  //             child: IconButton(
                  //               padding: EdgeInsets.zero,
                  //               onPressed: () async {
                  //                 setState(() {
                  //                   quantity = quantity + 1;
                  //                 });
                  //               },
                  //               icon: const Icon(
                  //                 Icons.add_rounded,
                  //                 size: 27,
                  //                 color: Colors.black54,
                  //               ),
                  //             ),
                  //           ),
                  //           Positioned(
                  //             bottom: 1,
                  //             left: -6,
                  //             child: IconButton(
                  //               padding: EdgeInsets.zero,
                  //               onPressed: () {
                  //                 if (quantity > 1) {
                  //                   setState(() {
                  //                     quantity = quantity - 1;
                  //                   });
                  //                 }
                  //               },
                  //               icon: const Icon(
                  //                 Icons.minimize_rounded,
                  //                 size: 27,
                  //                 color: Colors.black54,
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  _sizedBox20,
                  _buildProductRating(),
                  _sizedBox20,
                  _buildRelatedBooks(),
                  // const Text(
                  //   "Retailer's Contact",
                  //   style: TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // Text(widget.product['retailerName'])
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: customBottomSheet(size.height),
    );
  }

  int _currentPage = 0;

  Row _buildDots() {
    List<Widget> dots = [];
    for (int i = 0; i < widget.product['productImages'].length; i++) {
      dots.add(Container(
        margin: const EdgeInsets.all(5),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == i
              ? AppConstants.kPrimaryColor1
              : AppConstants.kGrey2,
        ),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots,
    );
  }

  String formatCurrency(dynamic price) {
    try {
      double numericPrice;
      if (price == null) return '0 đ';

      // Nếu price là String
      if (price is String) {
        // Loại bỏ tất cả ký tự không phải số
        String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
        numericPrice = double.tryParse(cleanPrice) ?? 0;
      }
      // Nếu price là số
      else if (price is num) {
        numericPrice = price.toDouble();
      }
      // Trường hợp khác
      else {
        return '0 đ';
      }

      // Format số theo định dạng tiền Việt Nam
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(numericPrice)} đ';
    } catch (e) {
      print('Error formatting price: $e');
      return '0 đ';
    }
  }

  Widget customBottomSheet(double height) {
    return Container(
      height: height * 0.08,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Phần chọn số lượng
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nút giảm
                InkWell(
                  onTap: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                  child: Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Hiển thị số lượng
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Nút tăng - thêm kiểm tra maxQuantity
                InkWell(
                  onTap: () {
                    if (quantity < maxQuantity) {
                      setState(() {
                        quantity++;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Số lượng sản phẩm có sẵn tối đa là $maxQuantity'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nút Thêm vào giỏ hàng
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: TextButton(
                onPressed: () {
                  if (quantity <= maxQuantity) {
                    _addToCart();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Số lượng vượt quá số lượng có sẵn'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'THÊM VÀO\nGIỎ HÀNG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          // Nút Mua ngay
          Expanded(
            child: Container(
              height: double.infinity,
              color: Colors.black,
              child: TextButton(
                onPressed: () {
                  _addToCart();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppConstants.kPrimaryColor1,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'MUA NGAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tách logic thêm vào giỏ hàng thành một hàm riêng
  void _addToCart() async {
    try {
      // Kiểm tra số lượng trước khi thêm vào giỏ hàng
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số lượng phải lớn hơn 0')),
        );
        return;
      }

      final box =
          await Hive.openBox<PlaceOrderItem>(AppConstants.cartProductHiveKey);

      // Tạo item mới với số lượng đã kiểm tra
      PlaceOrderItem placeOrderItem = PlaceOrderItem(
        productId: widget.product['productId'],
        quantity: quantity.toString(), // Đảm bảo quantity > 0
        productName: widget.product['productName'],
        productRetail: widget.product['productRetail'].toString(),
        retialerId: widget.product['retailerId'],
        retailerName: widget.product['retailerName'],
        imageLink: widget.product['productImages'][0],
      );

      // Kiểm tra và cập nhật số lượng nếu sản phẩm đã tồn tại
      var existingItems = box.values
          .where((item) => item.productId == placeOrderItem.productId)
          .toList();

      if (existingItems.isNotEmpty) {
        var existingItem = existingItems.first;
        int newQuantity = int.parse(existingItem.quantity) + quantity;

        // Kiểm tra tổng số lượng không vượt quá maxQuantity
        if (newQuantity > maxQuantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Tổng số lượng không thể vượt quá $maxQuantity')),
          );
          return;
        }

        // Cập nhật số lượng mới
        existingItem.quantity = newQuantity.toString();
        await box.put(existingItem.key, existingItem);
      } else {
        // Thêm mới nếu chưa tồn tại
        await box.add(placeOrderItem);
      }

      // Debug log
      print('Current cart items:');
      box.values
          .forEach((item) => print('${item.productName}: ${item.quantity}'));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm vào giỏ hàng: $e')),
      );
    }
  }

  void _showPreviewImages() {
    List<String> previewImages = [];
    if (widget.product['preview_images'] != null &&
        widget.product['preview_images'].isNotEmpty) {
      previewImages = widget.product['preview_images'].toString().split(',');
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hình ảnh xem trước',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                height: 300,
                child: previewImages.isEmpty
                    ? Center(child: Text('Không có hình ảnh xem trước'))
                    : PageView.builder(
                        itemCount: previewImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPreviewPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            previewImages[index].trim(),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                  child: Text('Không thể tải hình ảnh'));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview({
    required String content,
    required double rating,
  }) async {
    try {
      // Lấy token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiStrings.hostNameUrl}/api/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Thêm 'Bearer ' vào trước token
        },
        body: jsonEncode({
          'book_id': widget.product['productId'],
          'comment': content,
          'rating': rating,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        // Token hết hạn
        await prefs.remove('token'); // Xóa token cũ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại'),
          ),
        );
        // Chuyển về màn hình đăng nhập
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login', // Thay thế bằng route đăng nhập của bạn
          (route) => false,
        );
        return;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá đã được gửi thành công')),
        );
        // Refresh đánh giá
        await fetchReviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi gửi đánh giá')),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi gửi đánh giá')),
      );
    }
  }

  void calculateRatings() {
    if (reviews.isEmpty) {
      averageRating = 0.0;
      totalReviews = 0;
      ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      return;
    }

    double totalStars = 0;
    totalReviews = reviews.length;
    ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      int rating = (review['rating'] ?? 5).toInt();
      if (rating < 1) rating = 1;
      if (rating > 5) rating = 5;

      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      totalStars += rating;
    }

    averageRating = totalReviews > 0 ? totalStars / totalReviews : 0.0;
  }

  int calculatePercentage(int stars) {
    if (totalReviews == 0) return 0;
    return ((ratingCounts[stars] ?? 0) / totalReviews * 100).round();
  }

  Widget _buildProductRating() {
    if (_isLoadingReviews) {
      return Center(child: CircularProgressIndicator());
    }

    double averageRating = _calculateAverageRating(reviews);
    int totalReviews = reviews.length;
    Map<String, dynamic>? latestReview =
        reviews.isNotEmpty ? reviews.first : null;

    return InkWell(
      onTap: () => _showReviewsDialog(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ĐÁNH GIÁ SẢN PHẨM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          SizedBox(height: 8),

          // Rating summary
          Row(
            children: [
              RatingBar.builder(
                initialRating: averageRating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 16,
                ignoreGestures: true,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {},
              ),
              SizedBox(width: 8),
              Text(
                '${averageRating.toStringAsFixed(1)}/5',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '($totalReviews đánh giá)',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // Latest review
          if (latestReview != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  child: Text(latestReview['full_name']?[0] ?? 'A'),
                  backgroundColor: Colors.grey[300],
                  radius: 16,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latestReview['full_name'] ?? 'Ẩn danh',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating:
                              (latestReview['rating'] ?? 5).toDouble(),
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 12,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {},
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(latestReview['created_at']),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              latestReview['comment'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Divider(height: 24),
        ],
      ),
    );
  }

  void _showReviewsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header với nút back
            Container(
              color: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'KHÁCH HÀNG NHẬN XÉT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Rating Summary
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Điểm trung bình và số đánh giá
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('/5', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    '($totalReviews đánh giá)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),

                  // Rating Bars
                  _buildRatingBar(5),
                  _buildRatingBar(4),
                  _buildRatingBar(3),
                  _buildRatingBar(2),
                  _buildRatingBar(1),

                  // Nút viết đánh giá
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showWriteReviewScreen();
                    },
                    icon: Icon(Icons.edit),
                    label: Text('VIẾT ĐÁNH GIÁ'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 45),
                      side: BorderSide(color: Colors.black),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Danh sách đánh giá
            Expanded(
              child: reviews.isEmpty
                  ? Center(child: Text('Chưa có đánh giá nào'))
                  : ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) =>
                          _buildReviewItem(reviews[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo rating bar
  Widget _buildRatingBar(int stars) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$stars sao',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: calculatePercentage(stars) / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${calculatePercentage(stars)}%',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'NHẬN XÉT SẢN PHẨM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Đánh giá sao
                    Text(
                      'Đánh giá sản phẩm :',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: 5,
                      minRating: 1,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemSize: 40,
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        userRating = rating;
                      },
                    ),
                    SizedBox(height: 24),

                    // Input họ tên
                    TextField(
                      controller: reviewNameController,
                      decoration: InputDecoration(
                        hintText: 'Nhập họ và tên',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Input title
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu để',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Input nội dung
                    TextField(
                      controller: reviewContentController,
                      maxLength: 100,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Viết nhận xét cho sản phẩm (Tối thiểu 100 ký tự)',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          reviewContentLength = value.length;
                        });
                      },
                    ),
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: Text(
                    //     '($reviewContentLength ký tự)',
                    //     style: TextStyle(color: Colors.grey),
                    //   ),
                    // ),
                    SizedBox(height: 24),

                    // Nút gửi
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (reviewContentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Vui lòng nhập nội dung đánh giá')),
                            );
                            return;
                          }

                          _submitReview(
                            content: reviewContentController.text,
                            rating: userRating,
                          );

                          reviewNameController.clear();
                          reviewContentController.clear();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.kPrimaryColor1,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'GỬI NHẬN XÉT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Thêm hàm kiểm tra token
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Hàm tính rating trung bình
  double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total =
        reviews.fold(0.0, (sum, review) => sum + (review['rating'] ?? 0.0));
    return total / reviews.length;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('Error parsing date: $e');
      return '';
    }
  }

  // Thêm hàm tính ngày giao hàng
  String _getEstimatedDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(Duration(days: 3));
    return '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}';
  }

  // Thêm dialog thông tin đổi trả
  void _showReturnPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Chính sách đổi trả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Điều kiện đổi trả',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('- Sản phẩm còn nguyên tem mác, chưa qua sử dụng'),
                Text('- Sản phẩm không bị hư hỏng, rách nát'),
                Text('- Có hóa đơn mua hàng kèm theo'),
                SizedBox(height: 12),
                Text(
                  '2. Thời gian đổi trả',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('- Trong vòng 30 ngày kể từ ngày nhận hàng'),
                Text('- Thời gian xử lý đổi trả: 3-5 ngày làm việc'),
                SizedBox(height: 12),
                Text(
                  '3. Hình thức đổi trả',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('- Đổi sản phẩm mới cùng loại'),
                Text('- Hoàn tiền qua tài khoản ngân hàng'),
                Text('- Hoàn tiền mặt tại cửa hàng'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchRelatedBooks() async {
    if (_isLoadingRelated) return;

    try {
      setState(() => _isLoadingRelated = true);
      final categoryId = widget.product['productCategory'];
      final currentBookId = widget.product['productId'];

      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/books/category/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final allBooks = (data['data'] as List)
            .map((book) => {
                  'productId': book['book_id']?.toString() ?? 'unknown_id',
                  'book_id': book['book_id']?.toString() ?? 'unknown_id',
                  'productName': book['title'] ?? 'Unknown Title',
                  'productDescription': book['description'] ?? 'No description',
                  'productRetail': book['price']?.toString() ?? '0',
                  'productImages': [
                    book['image_url'] ?? 'https://via.placeholder.com/128x196'
                  ],
                  'productCompany': 'Book Store',
                  'productCategory':
                      book['category_id']?.toString() ?? 'General',
                  'retailerName': book['author'] ?? 'Unknown Author',
                  'productSizes': 'Standard',
                  'productColors': 'Default',
                  'quantity': book['quantity']?.toString() ?? '1',
                  'preview_images': book['preview_images'] ?? [],
                  'retailerId': book['author_id']?.toString() ?? 'unknown',
                  'averageRating': book['average_rating'] ?? 0.0,
                  'totalReviews': book['total_reviews'] ?? 0,
                  'ratings': book['ratings'] ?? {},
                })
            .where((book) => book['productId'] != currentBookId)
            .take(6)
            .toList();

        setState(() {
          relatedBooks = allBooks;
        });
      }
    } catch (e) {
      print('Error fetching related books: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  Widget _buildRelatedBooks() {
    if (_isLoadingRelated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (relatedBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'SÁCH CÙNG THỂ LOẠI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: min(relatedBooks.length, 6),
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddToCartScreen(
                          product: relatedBooks[index],
                        ),
                      ),
                    );
                  },
                  child: ProductGridTile(product: relatedBooks[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> fetchReviews() async {
    try {
      setState(() => _isLoadingReviews = true);
      final response = await http.get(
        Uri.parse(
            '${ApiStrings.hostNameUrl}/api/reviews/${widget.product['productId']}'),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          reviews = List<Map<String, dynamic>>.from(data['data'] ?? []);
          calculateRatings();
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(review['full_name']?[0] ?? 'A'),
        backgroundColor: Colors.grey[300],
      ),
      title: Text(review['full_name'] ?? 'Ẩn danh'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBar.builder(
            initialRating: (review['rating'] ?? 5).toDouble(),
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 12,
            ignoreGestures: true,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {},
          ),
          Text(review['comment'] ?? ''),
        ],
      ),
    );
  }

  // Thêm widget hiển thị cảnh báo khi số lượng gần hết
  Widget _buildQuantityWarning() {
    if (maxPurchasableQuantity <= 5) {
      return Container(
        padding: EdgeInsets.all(8),
        color: Colors.red.shade100,
        child: Text(
          'Chỉ còn $maxPurchasableQuantity sản phẩm',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildPreviewButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: previewImages.isEmpty ? null : _showPreviewDialog,
              icon: Icon(Icons.preview),
              label: Text('Đọc thử'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.kPrimaryColor1,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _speakPreviewText,
              icon: Icon(isPlaying ? Icons.stop : Icons.volume_up),
              label: Text(isPlaying ? 'Dừng' : 'Nghe'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPlaying ? Colors.red : AppConstants.kPrimaryColor1,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                AppBar(
                  backgroundColor: AppConstants.kPrimaryColor1,
                  title: Text('Đọc thử'),
                  leading: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    itemCount: previewImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.network(
                          previewImages[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Center(
                              child: Text('Không thể tải hình ảnh'),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Trang ${currentImageIndex + 1}/${previewImages.length}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _speakPreviewText() async {
    try {
      if (previewImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không có hình ảnh để đọc')),
        );
        return;
      }

      if (isPlaying) {
        await flutterTts.stop();
        setState(() => isPlaying = false);
        return;
      }

      setState(() => isPlaying = true);

      // Tải hình ảnh từ URL
      final response =
          await http.get(Uri.parse(previewImages[currentImageIndex]));
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Nhận diện text từ hình ảnh
      final inputImage = InputImage.fromFile(tempFile);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String textToSpeak = recognizedText.text;
      print('Recognized text: $textToSpeak'); // Debug log

      if (textToSpeak.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không nhận diện được text trong hình')),
        );
        setState(() => isPlaying = false);
        return;
      }

      await flutterTts.setLanguage('vi-VN');
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.6);
      await flutterTts.setVolume(1.0);

      flutterTts.setCompletionHandler(() {
        setState(() {
          isPlaying = false;
          // Chuyển sang hình tiếp theo nếu có
          if (currentImageIndex < previewImages.length - 1) {
            currentImageIndex++;
            _speakPreviewText(); // Đọc hình tiếp theo
          } else {
            currentImageIndex = 0; // Reset về hình đầu tiên
          }
        });
      });

      await flutterTts.speak(textToSpeak);
      textRecognizer.close();
    } catch (e) {
      print('Error in _speakPreviewText: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi đọc hình ảnh')),
      );
      setState(() => isPlaying = false);
    }
  }
}

class ReviewItem extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onShowAll;

  const ReviewItem({
    Key? key,
    required this.review,
    required this.onShowAll,
  }) : super(key: key);

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('Error parsing date: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(review['full_name']?[0] ?? 'A'),
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['full_name'] ?? 'Ẩn danh',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: (review['rating'] ?? 5).toDouble(),
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 16,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {},
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(review['created_at']),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            review['comment'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if ((review['comment']?.length ?? 0) > 100)
            TextButton(
              onPressed: onShowAll,
              child: Text(
                'Xem thêm',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}
