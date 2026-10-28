import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PosStore();
  await store.load();
  runApp(PosRetailPro(store: store));
}

const brandBlue = Color(0xFF1769D2);
const navy = Color(0xFF173E68);
const paleBlue = Color(0xFFEAF3FF);

class Product {
  Product({required this.id, required this.name, required this.category,
    required this.price, required this.stock});
  String id, name, category;
  double price;
  int stock;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'price': price, 'stock': stock};
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] ?? '', name: j['name'] ?? '', category: j['category'] ?? 'General',
    price: (j['price'] as num? ?? 0).toDouble(), stock: (j['stock'] as num? ?? 0).toInt());
}

class Customer {
  Customer({required this.id, required this.name, required this.phone});
  String id, name, phone;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};
  factory Customer.fromJson(Map<String, dynamic> j) => Customer(id: j['id'] ?? '', name: j['name'] ?? '', phone: j['phone'] ?? '');
}

class Sale {
  Sale({required this.id, required this.date, required this.total, required this.method, required this.items});
  String id, date, method;
  double total;
  int items;
  Map<String, dynamic> toJson() => {'id': id, 'date': date, 'total': total, 'method': method, 'items': items};
  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id: j['id'] ?? '', date: j['date'] ?? '', total: (j['total'] as num? ?? 0).toDouble(),
    method: j['method'] ?? 'Cash', items: (j['items'] as num? ?? 0).toInt());
}

class PosStore extends ChangeNotifier {
  static const _productsKey = 'pos_products_v1', _customersKey = 'pos_customers_v1', _salesKey = 'pos_sales_v1', _businessKey = 'pos_business_v1';
  final List<Product> products = [];
  final List<Customer> customers = [];
  final List<Sale> sales = [];
  String businessName = 'My Store';
  bool offline = true;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final rawProducts = p.getString(_productsKey);
    final rawCustomers = p.getString(_customersKey);
    final rawSales = p.getString(_salesKey);
    if (rawProducts == null) {
      products.addAll([
        Product(id:'p1', name:'Coca Cola 500ml', category:'Beverages', price:2500, stock:50),
        Product(id:'p2', name:'Mineral Water 500ml', category:'Beverages', price:1500, stock:100),
        Product(id:'p3', name:'Potato Chips', category:'Snacks', price:2000, stock:35),
        Product(id:'p4', name:'Bread', category:'Groceries', price:3000, stock:20),
        Product(id:'p5', name:'Rice 1kg', category:'Groceries', price:4500, stock:25),
      ]);
    } else {
      products.addAll((jsonDecode(rawProducts) as List).map((e) => Product.fromJson(Map<String,dynamic>.from(e))));
    }
    if (rawCustomers == null) {
      customers.addAll([
        Customer(id:'c1', name:'John Mwangi', phone:'+256 700 123456'),
        Customer(id:'c2', name:'Sarah Nakato', phone:'+256 772 987654'),
      ]);
    } else {
      customers.addAll((jsonDecode(rawCustomers) as List).map((e) => Customer.fromJson(Map<String,dynamic>.from(e))));
    }
    if (rawSales != null) sales.addAll((jsonDecode(rawSales) as List).map((e) => Sale.fromJson(Map<String,dynamic>.from(e))));
    businessName = p.getString(_businessKey) ?? 'My Store';
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_productsKey, jsonEncode(products.map((e)=>e.toJson()).toList()));
    await p.setString(_customersKey, jsonEncode(customers.map((e)=>e.toJson()).toList()));
    await p.setString(_salesKey, jsonEncode(sales.map((e)=>e.toJson()).toList()));
    await p.setString(_businessKey, businessName);
  }
  Future<void> addProduct(Product item) async { products.add(item); await _persist(); notifyListeners(); }
  Future<void> updateProduct(Product item) async {
    final i = products.indexWhere((p)=>p.id==item.id);
    if (i >= 0) products[i] = item;
    await _persist(); notifyListeners();
  }
  Future<void> addCustomer(Customer item) async { customers.add(item); await _persist(); notifyListeners(); }
  Future<void> completeSale(Map<Product,int> cart, String method) async {
    final total = cart.entries.fold<double>(0, (sum,e)=>sum + e.key.price*e.value);
    for (final entry in cart.entries) {
      final p = products.firstWhere((x)=>x.id==entry.key.id);
      p.stock = (p.stock - entry.value).clamp(0, 1 << 30);
    }
    sales.insert(0, Sale(id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String(), total: total, method: method, items: cart.values.fold(0,(a,b)=>a+b)));
    await _persist(); notifyListeners();
  }
  Future<void> saveBusinessName(String value) async { businessName = value.trim().isEmpty ? 'My Store' : value.trim(); await _persist(); notifyListeners(); }
  double get totalSales => sales.fold(0, (sum,s)=>sum+s.total);
  int get lowStockCount => products.where((p)=>p.stock < 10).length;
}

class PosRetailPro extends StatelessWidget {
  const PosRetailPro({super.key, required this.store});
  final PosStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'POS Retail Pro', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: brandBlue), useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F8FC), appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white)),
    home: SplashScreen(store: store),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.store});
  final PosStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors:[navy, brandBlue], begin:Alignment.topLeft, end:Alignment.bottomRight)),
      child: SafeArea(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.shopping_cart_rounded, size: 68, color: brandBlue)),
        const SizedBox(height:24), const Text('POS Retail Pro', style: TextStyle(fontSize:32, color:Colors.white, fontWeight:FontWeight.bold)),
        const SizedBox(height:12), const Text('Manage your business anytime, anywhere.', textAlign:TextAlign.center, style:TextStyle(color:Colors.white70, fontSize:16)),
        const SizedBox(height:44), SizedBox(width:double.infinity, height:52, child:FilledButton(
          style:FilledButton.styleFrom(backgroundColor:Colors.white, foregroundColor:navy),
          onPressed:()=>Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>LoginScreen(store:store))),
          child:const Text('Get Started', style:TextStyle(fontWeight:FontWeight.bold)))),
        const SizedBox(height:20), const Text('Simple • Secure • Offline Ready', style:TextStyle(color:Colors.white70)),
      ]))),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store});
  final PosStore store;
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool obscure = true, remember = true;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  void login() {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter an email or phone and password to continue.')));
      return;
    }
    // Demo sign-in: production apps should validate credentials through a secure auth provider.
    Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>MainShell(store:widget.store)));
  }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24), child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460), child:Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
    Align(alignment:Alignment.centerLeft, child:IconButton(onPressed:()=>Navigator.maybePop(context), icon:const Icon(Icons.arrow_back))),
    const SizedBox(height:10), const Icon(Icons.lock_person_rounded, size:64, color:brandBlue),
    const SizedBox(height:16), const Text('Welcome back', textAlign:TextAlign.center, style:TextStyle(fontSize:28,fontWeight:FontWeight.bold,color:navy)),
    const SizedBox(height:8), const Text('Sign in to manage your store', textAlign:TextAlign.center, style:TextStyle(color:Colors.black54)),
    const SizedBox(height:30), TextField(controller:email, keyboardType:TextInputType.emailAddress, decoration:const InputDecoration(labelText:'Email or phone', prefixIcon:Icon(Icons.person_outline))),
    const SizedBox(height:14), TextField(controller:password, obscureText:obscure, decoration:InputDecoration(labelText:'Password', prefixIcon:const Icon(Icons.lock_outline), suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure), icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),
    CheckboxListTile(contentPadding:EdgeInsets.zero, value:remember, onChanged:(v)=>setState(()=>remember=v??false), title:const Text('Remember me'), controlAffinity:ListTileControlAffinity.leading),
    const SizedBox(height:10), SizedBox(height:52, child:FilledButton(onPressed:login, child:const Text('Login'))),
    const SizedBox(height:16), TextButton(onPressed:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Password recovery'),content:const Text('Connect a secure authentication provider to send password reset links.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))])), child:const Text('Forgot password?')),
    const SizedBox(height:18), const Text('Demo mode: enter any non-empty email/phone and password.', textAlign:TextAlign.center, style:TextStyle(color:Colors.black54,fontSize:12)),
  ])))));
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store});
  final PosStore store;
  @override State<MainShell> createState()=>_MainShellState();
}
class _MainShellState extends State<MainShell> {
  int index=0;
  @override Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(store:widget.store, go:(i)=>setState(()=>index=i)),
      SalesScreen(store:widget.store),
      InventoryScreen(store:widget.store),
      CustomersScreen(store:widget.store),
      ReportsScreen(store:widget.store),
      SettingsScreen(store:widget.store),
    ];
    return Scaffold(
      appBar: AppBar(title:Row(children:[const Icon(Icons.shopping_cart_rounded),const SizedBox(width:10),Expanded(child:Text(widget.store.businessName, overflow:TextOverflow.ellipsis))]), actions:[Padding(padding:const EdgeInsets.only(right:14),child:Icon(widget.store.offline?Icons.cloud_off_outlined:Icons.cloud_done_outlined))]),
      body:IndexedStack(index:index, children:pages),
      bottomNavigationBar:NavigationBar(selectedIndex:index, onDestinationSelected:(v)=>setState(()=>index=v), destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
        NavigationDestination(icon:Icon(Icons.point_of_sale_outlined),selectedIcon:Icon(Icons.point_of_sale),label:'Sales'),
        NavigationDestination(icon:Icon(Icons.inventory_2_outlined),selectedIcon:Icon(Icons.inventory_2),label:'Inventory'),
        NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'Customers'),
        NavigationDestination(icon:Icon(Icons.bar_chart_outlined),selectedIcon:Icon(Icons.bar_chart),label:'Reports'),
        NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'Settings'),
      ]),
    );
  }
}

String money(num n) => 'UGX ${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m)=>'${m[1]},')}';
Widget pageTitle(String title, String subtitle)=>Padding(padding:const EdgeInsets.fromLTRB(16,18,16,8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold,color:navy)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.black54))]));
Widget metricCard(String title,String value,IconData icon,{Color color=brandBlue})=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.04),blurRadius:12,offset:const Offset(0,4))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color,size:25),const SizedBox(height:14),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),const SizedBox(height:4),Text(title,style:const TextStyle(color:Colors.black54,fontSize:12))]));

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key,required this.store,required this.go});
  final PosStore store; final ValueChanged<int> go;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_)=>ListView(padding:const EdgeInsets.only(bottom:24),children:[
    pageTitle('Good morning 👋','Here is what is happening in your store.'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[navy,brandBlue]),borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text("Today's recorded sales",style:TextStyle(color:Colors.white70)),const SizedBox(height:8),Text(money(store.totalSales),style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('${store.sales.length} completed transactions',style:const TextStyle(color:Colors.white70)),
    ]))),
    Padding(padding:const EdgeInsets.all(16),child:GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.35,children:[
      InkWell(onTap:()=>go(1),child:metricCard('New sale','Start checkout',Icons.add_shopping_cart)),
      InkWell(onTap:()=>go(2),child:metricCard('Products','${store.products.length} items',Icons.inventory_2_outlined,color:Colors.teal)),
      InkWell(onTap:()=>go(3),child:metricCard('Customers','${store.customers.length} saved',Icons.people_outline,color:Colors.deepPurple)),
      InkWell(onTap:()=>go(4),child:metricCard('Low stock','${store.lowStockCount} alerts',Icons.warning_amber_outlined,color:Colors.orange)),
    ])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Recent transactions',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),TextButton(onPressed:()=>go(4),child:const Text('View reports'))])),
    if(store.sales.isEmpty) const Padding(padding:EdgeInsets.all(24),child:Text('No sales recorded yet. Start a sale to see transactions here.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54)))
    else ...store.sales.take(5).map((s)=>ListTile(leading:const CircleAvatar(backgroundColor:paleBlue,child:Icon(Icons.receipt_long,color:brandBlue)),title:Text(money(s.total)),subtitle:Text('${s.method} • ${s.items} item(s)'),trailing:Text(s.date.substring(11,16)))),
  ]));
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key,required this.store}); final PosStore store;
  @override State<SalesScreen> createState()=>_SalesScreenState();
}
class _SalesScreenState extends State<SalesScreen>{
  final Map<Product,int> cart={}; String method='Cash'; String query='';
  double get total=>cart.entries.fold(0,(sum,e)=>sum+e.key.price*e.value);
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_) {
    final matches=widget.store.products.where((p)=>p.name.toLowerCase().contains(query.toLowerCase()) && p.stock>0).toList();
    return Column(children:[
      pageTitle('New sale','Choose products, set quantities, then complete payment.'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(hintText:'Search products...',prefixIcon:Icon(Icons.search)))),
      Expanded(child:ListView(children:matches.map((p)=>ListTile(leading:const CircleAvatar(backgroundColor:paleBlue,child:Icon(Icons.inventory_2_outlined,color:brandBlue)),title:Text(p.name),subtitle:Text('${money(p.price)} • Stock ${p.stock}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[
        if((cart[p]??0)>0) IconButton(onPressed:()=>setState(()=>cart[p]=(cart[p]??0)-1==0?0:(cart[p]??0)-1),icon:const Icon(Icons.remove_circle_outline)),
        if((cart[p]??0)>0) Text('${cart[p]}'),
        IconButton(onPressed:()=>setState(()=>cart[p]=(cart[p]??0)+1),icon:const Icon(Icons.add_circle,color:brandBlue)),
      ])).toList())),
      Container(padding:const EdgeInsets.fromLTRB(16,12,16,18),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(20))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('Items: ${cart.values.fold(0,(a,b)=>a+b)}'),Text(money(total),style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))]),
        const SizedBox(height:8),DropdownButtonFormField<String>(value:method,decoration:const InputDecoration(labelText:'Payment method',contentPadding:EdgeInsets.symmetric(horizontal:12,vertical:8)),items:const['Cash','Credit / Debit Card','Mobile Money','Bank Transfer'].map((m)=>DropdownMenuItem(value:m,child:Text(m))).toList(),onChanged:(v)=>setState(()=>method=v??'Cash')),
        const SizedBox(height:10),FilledButton.icon(onPressed:cart.values.fold(0,(a,b)=>a+b)==0?null:()async{
          final valid=Map<Product,int>.fromEntries(cart.entries.where((e)=>e.value>0));
          for(final e in valid.entries){if(e.value>e.key.stock){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Not enough stock for ${e.key.name}')));return;}}
          await widget.store.completeSale(valid,method); setState(()=>cart.clear());
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sale recorded successfully.')));
        },icon:const Icon(Icons.check_circle_outline),label:const Text('Complete sale')),
      ]))
    ]);
  });
}

class InventoryScreen extends StatefulWidget {const InventoryScreen({super.key,required this.store});final PosStore store;@override State<InventoryScreen> createState()=>_InventoryScreenState();}
class _InventoryScreenState extends State<InventoryScreen>{
  String query='';
  Future<void> addProduct() async {
    final name=TextEditingController(), category=TextEditingController(text:'General'), price=TextEditingController(), stock=TextEditingController();
    final result=await showDialog<Product>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Add product'),content:SingleChildScrollView(child:Column(children:[
      TextField(controller:name,decoration:const InputDecoration(labelText:'Product name')),
      TextField(controller:category,decoration:const InputDecoration(labelText:'Category')),
      TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price (UGX)')),
      TextField(controller:stock,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Opening stock')),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){final p=double.tryParse(price.text),s=int.tryParse(stock.text);if(name.text.trim().isEmpty||p==null||s==null||p<0||s<0)return;Navigator.pop(ctx,Product(id:DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),category:category.text.trim().isEmpty?'General':category.text.trim(),price:p,stock:s));},child:const Text('Save'))]));
    if(result!=null) await widget.store.addProduct(result);
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_)=>Column(children:[
    pageTitle('Inventory management','Track stock levels, prices and categories.'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(hintText:'Search inventory...',prefixIcon:Icon(Icons.search)))),
    Expanded(child:ListView(children:widget.store.products.where((p)=>p.name.toLowerCase().contains(query.toLowerCase())).map((p)=>ListTile(leading:const CircleAvatar(backgroundColor:paleBlue,child:Icon(Icons.inventory_2,color:brandBlue)),title:Text(p.name),subtitle:Text('${p.category} • ${money(p.price)}'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text('Stock: ${p.stock}',style:TextStyle(color:p.stock<10?Colors.red:Colors.black87,fontWeight:FontWeight.w600)),if(p.stock<10)const Text('LOW STOCK',style:TextStyle(color:Colors.red,fontSize:10))]),onTap:()=>showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(p.name),content:Text('Category: ${p.category}\\nPrice: ${money(p.price)}\\nStock: ${p.stock}'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close')),TextButton(onPressed:()async{Navigator.pop(ctx);final c=TextEditingController(text:'${p.stock}');final v=await showDialog<int>(context:context,builder:(d)=>AlertDialog(title:const Text('Adjust stock'),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'New stock quantity')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,int.tryParse(c.text)),child:const Text('Save'))]));if(v!=null&&v>=0){p.stock=v;await widget.store.updateProduct(p);}},child:const Text('Adjust stock'))])))).toList())),
    Padding(padding:const EdgeInsets.all(16),child:SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:addProduct,icon:const Icon(Icons.add),label:const Text('Add product'))))
  ]));
}

class CustomersScreen extends StatefulWidget {const CustomersScreen({super.key,required this.store});final PosStore store;@override State<CustomersScreen> createState()=>_CustomersScreenState();}
class _CustomersScreenState extends State<CustomersScreen>{
  String query='';
  Future<void> addCustomer()async{
    final name=TextEditingController(),phone=TextEditingController();
    final c=await showDialog<Customer>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Add customer'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Full name')),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone number'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){if(name.text.trim().isEmpty)return;Navigator.pop(ctx,Customer(id:DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),phone:phone.text.trim()));},child:const Text('Save'))]));
    if(c!=null)await widget.store.addCustomer(c);
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_)=>Column(children:[
    pageTitle('Customers','Keep customer contacts organized.'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(hintText:'Search customers...',prefixIcon:Icon(Icons.search)))),
    Expanded(child:ListView(children:widget.store.customers.where((c)=>('${c.name} ${c.phone}').toLowerCase().contains(query.toLowerCase())).map((c)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),title:Text(c.name),subtitle:Text(c.phone.isEmpty?'No phone number':c.phone),trailing:const Icon(Icons.chevron_right))).toList())),
    Padding(padding:const EdgeInsets.all(16),child:SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:addCustomer,icon:const Icon(Icons.person_add_alt_1),label:const Text('Add customer'))))
  ]));
}

class ReportsScreen extends StatelessWidget {const ReportsScreen({super.key,required this.store});final PosStore store;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_) {
    final methods=<String,double>{};for(final s in store.sales){methods[s.method]=(methods[s.method]??0)+s.total;}
    final maxValue=methods.values.fold<double>(0,(a,b)=>a>b?a:b);
    return ListView(padding:const EdgeInsets.only(bottom:24),children:[
      pageTitle('Reports & analytics','Summary of the sales recorded on this device.'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:metricCard('Total recorded sales',money(store.totalSales),Icons.payments_outlined)),
      Padding(padding:const EdgeInsets.all(16),child:Row(children:[Expanded(child:metricCard('Transactions','${store.sales.length}',Icons.receipt_long)),const SizedBox(width:12),Expanded(child:metricCard('Products sold','${store.sales.fold<int>(0,(a,s)=>a+s.items)}',Icons.shopping_bag_outlined))])),
      Padding(padding:const EdgeInsets.fromLTRB(16,8,16,4),child:Text('Sales by payment method',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold))),
      if(methods.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('Complete a sale to start generating reports.'))
      else ...methods.entries.map((e)=>Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(e.key),Text(money(e.value),style:const TextStyle(fontWeight:FontWeight.w600))]),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:maxValue==0?0:e.value/maxValue,minHeight:10,backgroundColor:paleBlue))]))),
      const Padding(padding:EdgeInsets.all(16),child:Text('Reports use locally recorded transactions. Connect a backend to synchronize across devices and generate audited tax reports.',style:TextStyle(color:Colors.black54,fontSize:12))),
    ];
  });
}

class SettingsScreen extends StatelessWidget {const SettingsScreen({super.key,required this.store});final PosStore store;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_)=>ListView(padding:const EdgeInsets.only(bottom:24),children:[
    pageTitle('Settings','Personalize and manage your POS application.'),
    ListTile(leading:const CircleAvatar(child:Icon(Icons.storefront)),title:Text(store.businessName,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('Business profile'),trailing:const Icon(Icons.chevron_right),onTap:()async{final c=TextEditingController(text:store.businessName);final v=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Business profile'),content:TextField(controller:c,decoration:const InputDecoration(labelText:'Business name')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text),child:const Text('Save'))]));if(v!=null)await store.saveBusinessName(v);}),
    const Divider(),
    SwitchListTile(value:store.offline,onChanged:(v){store.offline=v;store.notifyListeners();},secondary:const Icon(Icons.cloud_off_outlined),title:const Text('Offline mode'),subtitle:const Text('This demo stores data on this device.')),
    const ListTile(leading:Icon(Icons.payment_outlined),title:Text('Payment settings'),subtitle:Text('Cash, card, mobile money and bank transfer options')),
    const ListTile(leading:Icon(Icons.security_outlined),title:Text('Security & privacy'),subtitle:Text('Demo login is not production authentication')),
    const ListTile(leading:Icon(Icons.devices_outlined),title:Text('Cross-platform'),subtitle:Text('Flutter project for Android and iOS')),
    const ListTile(leading:Icon(Icons.info_outline),title:Text('About POS Retail Pro'),subtitle:Text('Version 1.0.0 • Assignment project')),
    Padding(padding:const EdgeInsets.all(16),child:OutlinedButton.icon(onPressed:()=>Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>SplashScreen(store:store)),(r)=>false),icon:const Icon(Icons.logout),label:const Text('Log out'))),
  ]));
}
