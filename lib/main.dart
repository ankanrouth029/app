import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'blog_model.dart';

void main() async {
  // Register the adapter for BlogModel
  Hive.registerAdapter(BlogModelAdapter());

  // Open Hive box and start the app
  await Hive.openBox<BlogModel>('favorite_blogs');

  runApp(MyApp());
}

class BlogModelAdapter extends TypeAdapter<BlogModel> {
  @override
  int get typeId => 0; // Unique ID for this adapter

  @override
  BlogModel read(BinaryReader reader) {
    final title = reader.read();
    final imageUrl = reader.read();
    return BlogModel(title: title, imageUrl: imageUrl);
  }

  @override
  void write(BinaryWriter writer, BlogModel obj) {
    writer.write(obj.title);
    writer.write(obj.imageUrl);
  }
}

class AllBlogsPage extends StatefulWidget {
  @override
  _AllBlogsPageState createState() => _AllBlogsPageState();
}

class _AllBlogsPageState extends State<AllBlogsPage> {
  List<dynamic> blogs = [];
  final String url = 'https://intent-kit-16.hasura.app/api/rest/blogs';
  final String adminSecret =
      '32qR4KmXOIpsGPQKMqEJHGJS27G5s7HdSKO3gdtQd2kv5e852SiYwWNfxkZOBuQ6';

  void fetchBlogs() async {
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'x-hasura-admin-secret': adminSecret,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('blogs') &&
            responseData['blogs'] is List<dynamic>) {
          final List<dynamic> blogList = responseData['blogs'];

          setState(() {
            blogs = blogList;
          });
        } else {
          print(
              'JSON structure does not match expectations. Missing "blogs" key or invalid format.');
        }
      } else {
        // Request failed
        print('Request failed with status code: ${response.statusCode}');
        print('Response data: ${response.body}');
      }
    } catch (e) {
      // Handle any errors that occurred during the request
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBlogs();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final blog = blogs[index];
        final String title = blog['title'];
        final String imageUrl = blog['image_url'];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlogDetailPage(
                  title: title,
                  imageUrl: imageUrl,
                ),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(
                vertical: 12, horizontal: 10),
            child: Card(
              child: Column(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FavoriteBlogsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorite Blogs"),
        backgroundColor: Color(0xFF1B1B1B),
      ),
      body: FutureBuilder<Box<BlogModel>>(
        future: Hive.openBox<BlogModel>('favorite_blogs'),
        builder: (BuildContext context, AsyncSnapshot<Box<BlogModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // If the box is still loading, show a loading indicator
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If there's an error, display an error message
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // If there are no favorite blogs, display a message
            return Center(child: Text("No favorite blogs yet."));
          } else {
            // If there are favorite blogs, display them
            final favoriteBlogsBox = snapshot.data!;
            final favoriteBlogs = favoriteBlogsBox.values.toList();

            return ListView.builder(
              itemCount: favoriteBlogs.length,
              itemBuilder: (BuildContext context, int index) {
                final blog = favoriteBlogs[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlogDetailPage(
                          title: blog.title,
                          imageUrl: blog.imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    child: Card(
                      child: Column(
                        children: [
                          Image.network(
                            blog.imageUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                          ListTile(
                            title: Text(
                              blog.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class BlogDetailPage extends StatelessWidget {
  final String title;
  final String imageUrl;

  BlogDetailPage({
    required this.title,
    required this.imageUrl,
  });

  void addToFavorites() async {
    final favoriteBlogsBox = await Hive.openBox<BlogModel>('favorite_blogs');

    final blogToAdd = BlogModel(title: title, imageUrl: imageUrl);

    await favoriteBlogsBox.add(blogToAdd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color(0xFF1B1B1B),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: addToFavorites,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              addToFavorites();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl),
          ],
        ),
      ),
    );
  }
}



class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    AllBlogsPage(),
    FavoriteBlogsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: SizedBox(
            height: 85,
            child: Image.network(
              'https://cdn.subspace.money/whatsub_blogs/q.png',
              fit: BoxFit.contain,
            ),
          ),
          backgroundColor: Color(0xFF1B1B1B),
        ),
        body: _pages[_currentIndex], // Display the currently selected page
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex, // Set the current active item
          onTap: (index) {
            setState(() {
              _currentIndex = index; // Update the current page when tapped
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: "All Blogs",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Favorite Blogs",
            ),
          ],
        ),
      ),
    );
  }
}
