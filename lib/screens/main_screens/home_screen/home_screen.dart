import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_circularprogressbar.dart';
import 'package:booky/common/widgets/custom_textfield.dart';
import 'package:booky/common/widgets/product_grid_tile.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/main_screens/home_screen/sub_screens/add_to_cart_screen.dart';
import 'package:http/http.dart' as http;
import 'package:booky/screens/main_screens/home_screen/sub_screens/fav_products_screen.dart';
import 'package:booky/screens/main_screens/home_screen/sub_screens/notification_screen.dart';
import 'package:booky/screens/main_screens/home_screen/sub_screens/products_by_category_screen.dart';
import 'package:booky/screens/main_screens/home_screen/sub_screens/see_all_offers_screen.dart';
import 'package:booky/utils/api_strings.dart';
import 'package:booky/screens/admin_screens/admin_dashboard.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> allowedCategories = [
    {
      'name': 'Comic & Graphic Novel',
      'query': 'comic+graphic+novel',
      'companyImagePath': 'https://via.placeholder.com/100',
      'companyName': 'Comic Books'
    },
    {
      'name': 'Adventure Stories',
      'query': 'adventure+stories',
      'companyImagePath': 'https://via.placeholder.com/100',
      'companyName': 'Adventure Books'
    },
  ];

  String fullName = 'User';
  String? avatarUrl;
  List specialOffersImagesList = [];
  bool isSpecialOffersResponseGenerating = false;
  final Box myAppBox = Hive.box(AppConstants.appHiveBox);
  TextEditingController searchController = TextEditingController();
  List productsHiveList = [];
  List companiesList = [];
  List filteredProductsList = [];
  bool isDataLoaded = false;
  bool firstTimeLoading = true;
  Timer? _refreshTimer;
  List<Map<String, dynamic>> categories = [];
  bool showAllCategories = false;
  final int initialCategoryCount = 7;
  int userRoleId = 0;

  // Tạo formatter cho tiền VND
  final currencyFormatter = NumberFormat('#,###', 'vi_VN');

  Future<bool> getSpecialOffersFunc() async {
    try {
      print('getSpecialOffersFunc() CALLED!!!');

      String apiUrl =
          '${ApiStrings.hostNameUrl}${ApiStrings.getSpecialOffersUrl}';

      var prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      http.Response response = await http.get(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'token': token,
        },
      );

      // print('getSpecialOffers() response.body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == '200') {
          specialOffersImagesList = responseData['specialOffers'];

          return true;
        }
      }
      return false;
    } catch (e) {
      print('getSpecialOffersFunc() error ----------------------------> $e');
      return false;
    }
  }

  String formatCurrency(dynamic price) {
    if (price == null) return '0 đ';

    // Chuyển đổi price thành double
    double numericPrice;
    if (price is String) {
      // Loại bỏ các ký tự không phải số
      String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      numericPrice = double.tryParse(cleanPrice) ?? 0;
    } else {
      numericPrice = price.toDouble();
    }

    // Format số và thêm đơn vị đ
    return '${currencyFormatter.format(numericPrice)} đ';
  }

  Future<bool> getProductsFunc() async {
    try {
      print('getProductsFunc() CALLED!!!');
      List<Map<String, dynamic>> allBooks = [];

      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/books'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' || data['status'] == '200') {
          final books = data['data'] as List;

          for (var book in books) {
            try {
              // Format dữ liệu giống với products_by_category_screen
              var bookData = {
                'productId': book['book_id']?.toString() ?? '',
                'book_id': book['book_id']?.toString() ?? '',
                'productName': book['title'] ?? 'Unknown Title',
                'productDescription':
                    book['description'] ?? 'No description available',
                'productRetail': formatCurrency(book['price']),
                'numericPrice':
                    double.tryParse(book['price']?.toString() ?? '0') ?? 0.0,
                'productImages': [
                  book['image_url'] ?? 'https://via.placeholder.com/128x196'
                ],
                'productCompany': 'Book Store',
                'productCategory': book['category_id']?.toString() ?? 'General',
                'retailerName': book['author'] ?? 'Unknown Author',
                'productSizes': 'Standard', // Giá trị mặc định cho sách
                'productColors': 'Default', // Giá trị mặc định cho sách
                'quantity': book['quantity']?.toString() ?? '1',
                'preview_images': book['preview_images'] ?? [],
                'retailerId': book['author_id']?.toString() ?? '',
                'averageRating': book['average_rating'] ?? 0.0,
                'totalReviews': book['total_reviews'] ?? 0,
                'ratings': book['ratings'] ?? {},
              };

              // Kiểm tra các trường bắt buộc không được null
              if (bookData['productId'].isNotEmpty &&
                  bookData['productName'].isNotEmpty &&
                  bookData['productRetail'].isNotEmpty) {
                allBooks.add(bookData);
              }
            } catch (bookError) {
              print('Error processing book: $bookError');
              continue;
            }
          }

          if (mounted) {
            setState(() {
              productsHiveList = allBooks;
              filteredProductsList = allBooks;
            });
            await myAppBox.put(AppConstants.productHiveKey, allBooks);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error in getProductsFunc: $e');
      return false;
    }
  }

  void searchBooks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}/api/books/search?q=$query'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final books = data['data'] as List;
          List<Map<String, dynamic>> searchResults = [];

          for (var book in books) {
            try {
              var bookData = {
                'productId': book['id']?.toString() ?? 'unknown_id',
                'productName': book['title'] ?? 'Unknown Title',
                'productDescription':
                    book['description'] ?? 'No description available',
                'productRetail': book['price']?.toString() ?? 'Not available',
                'numericPrice':
                    double.tryParse(book['price']?.toString() ?? '0') ?? 0.0,
                'productImages': [
                  book['imageUrl'] ?? 'https://via.placeholder.com/128x196'
                ],
                'productCompany': book['publisher'] ?? 'Unknown Publisher',
                'productCategory': book['category'] ?? 'General',
                'retailerName': book['author'] ?? 'Unknown Author',
                'productSizes': book['format'] ?? 'Unknown Format',
                'pageCount': book['pageCount']?.toString() ?? 'Unknown',
                'publishedDate': book['publishedDate'] ?? 'Unknown',
                'language': book['language'] ?? 'en',
              };

              searchResults.add(bookData);
            } catch (bookError) {
              print('Error processing search result: $bookError');
              continue;
            }
          }

          setState(() {
            filteredProductsList = searchResults;
          });
        }
      }
    } catch (e) {
      print('Search error: $e');
    }
  }

  late Future<bool> getTheSpecialOffersFunc;
  late Future<bool> getTheProductFunc;

  Future<void> refreshBooks() async {
    if (mounted) {
      setState(() {
        firstTimeLoading = true;
        isDataLoaded = false;
      });

      bool success = await getProductsFunc();

      if (mounted) {
        setState(() {
          firstTimeLoading = false;
          if (success) {
            filteredProductsList = productsHiveList;
          }
        });
      }
    }
  }

  Future<void> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiStrings.hostNameUrl}${ApiStrings.getCategoriesUrl}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Categories Response - Status: ${response.statusCode}');
      print('Categories Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          if (mounted) {
            setState(() {
              companiesList = List<Map<String, dynamic>>.from(
                responseData['data'].map((category) => {
                      'category_id': category['category_id'],
                      'name': category['name'],
                      'category_image': category['category_image'],
                      'companyName': category['name'],
                      'companyImagePath': category['category_image'],
                      'query': category['name']
                          .toString()
                          .toLowerCase()
                          .replaceAll(' ', '+'),
                    }),
              );
              print('Loaded categories: $companiesList');
            });
          }
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadSavedUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedFullName = prefs.getString('full_name');
      String? savedAvatarUrl = prefs.getString('avatar_url');

      if (mounted) {
        setState(() {
          fullName = savedFullName ?? 'User';
          avatarUrl = savedAvatarUrl;
        });
      }
    } catch (e) {
      print('Error loading saved user info: $e');
      if (mounted) {
        setState(() {
          fullName = 'User';
          avatarUrl = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedUserInfo();
    getUserInfo();

    // Load categories from Hive first
    if (myAppBox.isNotEmpty) {
      productsHiveList = myAppBox.get(AppConstants.productHiveKey) ?? [];
      companiesList = myAppBox.get(AppConstants.companiesHiveKey) ?? [];
    }

    // Then fetch latest categories
    getCategories();

    if (!isDataLoaded) {
      getTheSpecialOffersFunc = getSpecialOffersFunc();
      getTheProductFunc = getProductsFunc();
      isDataLoaded = true;
    }

    filteredProductsList = productsHiveList;

    // Thêm timer để kiểm tra cập nhật
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      bool needsUpdate = prefs.getBool('books_updated') ?? false;

      if (needsUpdate && mounted) {
        await refreshBooks();
        await prefs.setBool('books_updated', false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('email');
      String token = prefs.getString('token') ?? '';

      if (savedEmail != null) {
        final response = await http.get(
          Uri.parse(
              '${ApiStrings.hostNameUrl}${ApiStrings.getUserInfoUrl}/$savedEmail'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final String? userFullName = responseData['fullName'];
          final String? serverAvatarUrl = responseData['avatarUrl'];
          final int roleId = responseData['role_id'] ?? 0;

          if (mounted) {
            setState(() {
              fullName = userFullName ?? 'User';
              if (serverAvatarUrl != null && serverAvatarUrl.isNotEmpty) {
                avatarUrl = serverAvatarUrl;
              }
              userRoleId = roleId;
            });

            // Cập nhật SharedPreferences
            await prefs.setString('full_name', userFullName ?? '');
            await prefs.setString('avatar_url', serverAvatarUrl ?? '');
            await prefs.setInt('role_id', roleId);
          }
        }
      }
    } catch (e) {
      print('Home - Error getting user info: $e');
    }
  }

  Widget _buildAvatar() {
    return avatarUrl != null && avatarUrl!.isNotEmpty
        ? CircleAvatar(
            backgroundImage: MemoryImage(
              base64Decode(avatarUrl!.split(',').last),
            ),
            radius: 20,
          )
        : const CircleAvatar(
            backgroundImage: AssetImage('assets/images/default_avatar.png'),
            radius: 20,
          );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshBooks,
          child: FutureBuilder(
              future: Future.wait([getTheProductFunc, getTheSpecialOffersFunc]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    searchController.text.isEmpty &&
                    firstTimeLoading == true) {
                  return const Center(
                    child: CustomCircularProgressBar(),
                  );
                } else {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Some error occured'),
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: AppConstants.defaultHorizontalPadding,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Visibility(
                                visible: searchController.text.isEmpty,
                                child: Row(
                                  children: [
                                    _buildAvatar(),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Xin chào 👋🏻',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(flex: 4),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                            NotificationScreen.routeName);
                                      },
                                      icon: const Icon(
                                        Icons.notifications_outlined,
                                        size: 30,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushNamed(
                                                FavProductsScreen.routeName)
                                            .then((value) {
                                          setState(() {});
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.favorite_outline_sharp,
                                        size: 30,
                                      ),
                                    ),
                                    if (userRoleId == 1)
                                      IconButton(
                                        icon: Icon(Icons.admin_panel_settings),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    AdminDashboard()),
                                          );
                                        },
                                      ),
                                  ],
                                )),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: const SizedBox(height: 20),
                            ),
                            CustomTextField(
                              label: 'Search',
                              textEditingController: searchController,
                              prefixIcon: const Icon(Icons.search),
                              onChanged: (String query) {
                                if (query.isNotEmpty) {
                                  searchBooks(query);
                                } else {
                                  setState(() {
                                    filteredProductsList = productsHiveList;
                                  });
                                }
                                firstTimeLoading = false;
                              },
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: const SizedBox(height: 10),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: Row(
                                children: [
                                  const Text(
                                    'Ưu đãi đặc biệt',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  // TextButton(
                                  //   onPressed: () {
                                  //     Navigator.of(context).pushNamed(
                                  //       SeeAllOffersScreen.routeName,
                                  //       arguments: specialOffersImagesList,
                                  //     );
                                  //   },
                                  //   child: const Text(
                                  //     'See all',
                                  //     style: TextStyle(color: Colors.black),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: const SizedBox(height: 10),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: Container(
                                height: 160,
                                width: double.maxFinite,
                                decoration: BoxDecoration(
                                  color: AppConstants.kGrey1,
                                  borderRadius: BorderRadius.circular(30),
                                  image: specialOffersImagesList.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            specialOffersImagesList[0]['image'],
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : const DecorationImage(
                                          image: AssetImage(
                                            'assets/images/sale_banners/sale_banner_1.jpg',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: const SizedBox(height: 20),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2 / 2.7,
                                ),
                                itemCount: showAllCategories
                                    ? companiesList.length
                                    : min(initialCategoryCount,
                                            companiesList.length) +
                                        (companiesList.length >
                                                initialCategoryCount
                                            ? 1
                                            : 0),
                                itemBuilder: (context, index) {
                                  // Nếu là ô cuối cùng và đang ở chế độ hiển thị thu gọn
                                  if (!showAllCategories &&
                                      index == initialCategoryCount &&
                                      companiesList.length >
                                          initialCategoryCount) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          showAllCategories = true;
                                        });
                                      },
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Container(
                                            height: 80,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: const Icon(
                                              Icons.grid_view,
                                              color:
                                                  AppConstants.kPrimaryColor1,
                                              size: 30,
                                            ),
                                          ),
                                          const Text(
                                            'Xem thêm',
                                            style: TextStyle(
                                              color:
                                                  AppConstants.kPrimaryColor1,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Hiển thị category bình thường
                                  final category = companiesList[
                                      showAllCategories ? index : index];
                                  print(
                                      'Category at index $index: $category'); // Debug log

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        ProductsByCategoryScreen.routeName,
                                        arguments: category,
                                      );
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Container(
                                          height: 80,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: category['category_image'] !=
                                                    null
                                                ? Image.network(
                                                    '${ApiStrings.hostNameUrl}${category['category_image']}',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error loading image for category ${category['name']}: $error');
                                                      return Container(
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: const Icon(
                                                            Icons.category,
                                                            color: Colors.grey),
                                                      );
                                                    },
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Icon(Icons.category,
                                                    color: Colors.grey),
                                          ),
                                        ),
                                        Text(
                                          category['name'] ??
                                              'Unknown Category',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: const SizedBox(height: 10),
                            ),
                            Visibility(
                              visible: searchController.text.isEmpty,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Sản phẩm mới',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Xem thêm',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ProductsGridList(
                              filteredProductsList: filteredProductsList,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  }
                }
              }),
        ),
      ),
    );
  }
}

class ProductsGridList extends StatelessWidget {
  const ProductsGridList({
    super.key,
    required this.filteredProductsList,
  });

  final List filteredProductsList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        itemCount: filteredProductsList.length,
        itemBuilder: (context, index) {
          final product = filteredProductsList[index];
          final quantity = int.parse(product['quantity'] ?? '0');

          return Stack(
            children: [
              InkWell(
                onTap: () {
                  if (quantity > 0) {
                    Navigator.pushNamed(
                      context,
                      AddToCartScreen.routeName,
                      arguments: {
                        ...product,
                        'quantity': quantity.toString(),
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sản phẩm đã hết hàng')),
                    );
                  }
                },
                child: ProductGridTile(product: product),
              ),
              if (quantity == 0)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Text(
                        'HẾT HÀNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (quantity > 0 && quantity <= 5)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Còn $quantity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
