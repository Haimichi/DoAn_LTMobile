import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booky/common/widgets/custom_button.dart';
import 'package:booky/constants.dart';
import 'package:booky/screens/authentication_screens/components/app_logo.dart';
import 'package:booky/screens/main_screens/cart_screen/sub_screens/shipping_address_screen.dart';
import 'package:booky/screens/main_screens/components/order_widget.dart';
import 'package:booky/screens/main_screens/home_screen/sub_screens/add_to_cart_screen.dart';
import 'package:intl/intl.dart';
import 'package:booky/models/PlaceOrderItem.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartList = [];
  List orderItemsId = [];
  List filteredProducts = [];

  int totalPrice = 0;

  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  calculateTotalPrice() async {
    try {
      totalPrice = 0;

      for (var item in cartList) {
        int quantity = int.tryParse(item.quantity?.toString() ?? '0') ?? 0;
        String priceStr = item.productRetail?.toString() ?? '0';
        priceStr = priceStr.replaceAll(RegExp(r'[^\d]'), '');
        int price = int.tryParse(priceStr) ?? 0;
        totalPrice += quantity * price;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.spTotalPrice, totalPrice);
      setState(() {});
    } catch (e) {
      print('Error calculating total price: $e');
    }
  }

  Future<void> getCartItems() async {
    try {
      // Kiểm tra và mở box nếu chưa mở
      if (!Hive.isBoxOpen(AppConstants.cartProductHiveKey)) {
        print('Opening cart box...');
        await Hive.openBox<PlaceOrderItem>(AppConstants.cartProductHiveKey);
      }

      final box = Hive.box<PlaceOrderItem>(AppConstants.cartProductHiveKey);
      print('Cart box is open: ${box.isOpen}');

      final items = box.values.toList();
      print('Items in cart: ${items.length}');

      // Debug: in chi tiết từng item
      for (var item in items) {
        print('Cart item: ${item.toJson()}');
      }

      if (mounted) {
        setState(() {
          cartList = items;
          orderItemsId = items.map((item) => item.productId).toList();
        });
        await calculateTotalPrice();
      }
    } catch (e) {
      print('Error getting cart items: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy giỏ hàng: $e')),
        );
      }
    }
  }

  // Thêm hàm để lưu item vào cart
  Future<void> addToCart(PlaceOrderItem item) async {
    try {
      final box = Hive.box<PlaceOrderItem>(AppConstants.cartProductHiveKey);

      // Kiểm tra sản phẩm đã tồn tại
      final existingItemIndex = box.values
          .toList()
          .indexWhere((existing) => existing.productId == item.productId);

      if (existingItemIndex != -1) {
        // Cập nhật số lượng nếu sản phẩm đã tồn tại
        final existingItem = box.getAt(existingItemIndex);
        final newQuantity =
            int.parse(existingItem!.quantity) + int.parse(item.quantity);

        final updatedItem = PlaceOrderItem(
          productName: item.productName,
          productRetail: item.productRetail,
          retialerId: item.retialerId,
          productId: item.productId,
          quantity: newQuantity.toString(),
          retailerName: item.retailerName,
          imageLink: item.imageLink,
        );

        await box.putAt(existingItemIndex, updatedItem);
      } else {
        // Thêm mới nếu sản phẩm chưa tồn tại
        await box.add(item);
      }

      print('Added/Updated item in cart: ${item.toJson()}');
      await getCartItems(); // Refresh cart list

      // Hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
        );
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm vào giỏ hàng: $e')),
        );
      }
    }
  }

  void handleClick(int item) {
    switch (item) {
      case 0:
        setState(() {
          cartList.clear();
        });
    }
  }

  void removeFromCart(int index) async {
    try {
      // Kiểm tra index hợp lệ
      if (index < 0 || index >= cartList.length) {
        print('Invalid index: $index');
        return;
      }

      // Lưu productId trước khi xóa
      final productIdToRemove = cartList[index].productId;

      // Mở box giỏ hàng
      final box =
          await Hive.openBox<PlaceOrderItem>(AppConstants.cartProductHiveKey);

      // Xóa item từ box dựa trên productId
      final itemsToRemove =
          box.values.where((item) => item.productId == productIdToRemove);
      for (var item in itemsToRemove) {
        final key = box.keyAt(box.values.toList().indexOf(item));
        await box.delete(key);
      }

      // Cập nhật state
      setState(() {
        cartList.removeAt(index);
        orderItemsId = cartList.map((item) => item.productId).toList();
        filteredProducts.removeWhere(
            (product) => product['productId'] == productIdToRemove);
      });

      // Tính lại tổng tiền
      calculateTotalPrice();

      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa sản phẩm khỏi giỏ hàng')),
      );

      // Đóng box
      await box.close();
    } catch (e) {
      print('Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi xóa sản phẩm')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Đảm bảo getCartItems được gọi sau khi widget được mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: AppConstants.kGrey1,
        appBar: AppBar(
          surfaceTintColor: AppConstants.kGrey1,
          backgroundColor: AppConstants.kGrey1,
          centerTitle: false,
          leading: const Padding(
            padding: EdgeInsets.only(left: 20),
            child: AppLogo(),
          ),
          title: const Text(
            'My Cart',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: PopupMenuButton<int>(
                onSelected: (item) => handleClick(item),
                itemBuilder: (context) => [
                  const PopupMenuItem<int>(
                    value: 0,
                    child: Text('Clear Cart List'),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomSheet: customBottomSheet(size.height),
        body: cartList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AppConstants.cartEmptyIcon,
                      height: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text('Cart is Empty'),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.02),
                    SizedBox(
                      child: ListView.separated(
                        itemCount: cartList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          int productQuantity =
                              int.parse(cartList[index].quantity);

                          var wholeProduct = filteredProducts.firstWhere(
                            (product) =>
                                product['productId'] ==
                                cartList[index].productId,
                            orElse: () => Map<String, dynamic>(),
                          );

                          // log('wholeProduct: $wholeProduct');

                          return OrderWidget(
                            label: cartList[index].productName,
                            retail: () {
                              try {
                                String priceStr = cartList[index]
                                    .productRetail
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                int price = int.tryParse(priceStr) ?? 0;
                                int quantity =
                                    int.tryParse(cartList[index].quantity) ?? 0;
                                return currencyFormatter
                                    .format(price * quantity);
                              } catch (e) {
                                print('Error calculating item price: $e');
                                return currencyFormatter.format(0);
                              }
                            }(),
                            quantity: cartList[index].quantity,
                            productImage: cartList[index].imageLink,
                            wholeProduct: wholeProduct,
                            isActive: false,
                            deleteFunc: () {
                              removeFromCart(index);
                            },
                            onTapFunc: () {
                              Navigator.pushNamed(
                                context,
                                AddToCartScreen.routeName,
                                arguments: wholeProduct,
                              );
                            },
                            mainButton: Container(
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                color: AppConstants.kGrey1,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      // border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppConstants.kGrey2,
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8,
                                          right: 8,
                                          top: 6,
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          cartList[index].quantity,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -5,
                                    top: 0,
                                    bottom: 0,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        setState(() {
                                          productQuantity = productQuantity + 1;
                                          cartList[index].quantity =
                                              productQuantity.toString();

                                          calculateTotalPrice();
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    left: -6,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        if (productQuantity > 1) {
                                          setState(() {
                                            productQuantity =
                                                productQuantity - 1;
                                            cartList[index].quantity =
                                                productQuantity.toString();

                                            calculateTotalPrice();
                                          });
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.minimize_rounded,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.13),
                  ],
                ),
              ));
  }

  customBottomSheet(double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.1,
      child: Container(
        decoration: const BoxDecoration(
          color: AppConstants.kGrey1,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.kGrey2,
              spreadRadius: 1.5,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'TỔNG TIỀN',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(totalPrice),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 60,
                width: 200,
                child: CustomButton(
                  label: 'THANH TOÁN',
                  onPress: () async {
                    try {
                      if (cartList.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Giỏ hàng trống!')),
                        );
                        return;
                      }

                      // Chuyển đổi cartList thành format phù hợp
                      List<Map<String, dynamic>> orderItems = cartList
                          .map((item) => {
                                'book_id': int.parse(item.productId),
                                'quantity': int.parse(item.quantity),
                                'price': double.parse(item.productRetail
                                    .replaceAll(RegExp(r'[^\d]'), '')),
                                'book_name': item.productName,
                                'image_url': item.imageLink,
                              })
                          .toList();

                      // Lưu vào SharedPreferences
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString(
                          'orderItems', jsonEncode(orderItems));

                      print('Order items saved: $orderItems'); // Debug log

                      final result = await Navigator.pushNamed(
                        context,
                        ShippingAddressScreen.routeName,
                      );

                      if (result == true) {
                        // Xóa giỏ hàng sau khi đặt hàng thành công
                        final box = await Hive.openBox<PlaceOrderItem>(
                            AppConstants.cartProductHiveKey);
                        await box.clear();
                        setState(() {
                          cartList.clear();
                          orderItemsId.clear();
                          totalPrice = 0;
                        });
                      }
                    } catch (e) {
                      print('Error navigating to shipping: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Có lỗi xảy ra: $e')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
