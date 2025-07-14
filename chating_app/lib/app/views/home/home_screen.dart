import 'package:chating_app/app/views/search/contect.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> recentChats = [
    {
      'name': 'Mithin',
      'message': 'Hey, how are you?',
      'time': '10:30 AM',
    },
    {
      'name': 'Vel',
      'message': 'Let’s meet tomorrow!',
      'time': '09:15 AM',
    },
    {
      'name': 'Arun',
      'message': 'Project file sent.',
      'time': 'Yesterday',
    },
  ];

  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  bool _isDarkMode = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AnimatedContainer(
          duration: Duration(seconds: 2),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Color(0xFF232526), Color(0xFF414345)]
                  : [Color(0xFFFF9800), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Text(
                  'TM Chats',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: _isDarkMode ? Colors.white : Colors.black),
                  tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by number...',
                  hintStyle: TextStyle(color: _isDarkMode ? const Color.fromARGB(179, 26, 25, 25) : const Color.fromARGB(255, 15, 15, 15)),
                  prefixIcon: Icon(Icons.search, color: _isDarkMode ? const Color.fromARGB(255, 19, 18, 18) : const Color.fromARGB(255, 15, 15, 15)),
                  filled: true,
                  fillColor: _isDarkMode ? const Color.fromARGB(255, 252, 253, 253) : Colors.indigo[50],
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          SizedBox(height: 8),
          PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab("Chats", 0),
                _buildTab("Groups", 1),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Chats Page
                ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    ...recentChats.map((chat) => Card(
                          color: _isDarkMode ? Colors.white : Colors.indigo[50],
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(chat['name']![0], style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black))),
                            title: Text(chat['name']!, style: TextStyle(color: _isDarkMode ? Colors.black : Colors.indigo[900], fontWeight: FontWeight.bold)),
                            subtitle: Text(chat['message']!, style: TextStyle(color: _isDarkMode ? Colors.black : Colors.indigo[700])),
                            trailing: Text(chat['time']!, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.black : Colors.indigo)),
                            onTap: () {
                              // TODO: Navigate to chat detail
                            },
                          ),
                        )),
                  ],
                ),
                // Groups Page
                ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    Card(
                      color: _isDarkMode ? Colors.indigo[50] : Colors.white,
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.group, color: Colors.indigo),
                        title: Text('Groups', style: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.black : Colors.indigo[900])),
                        subtitle: Text('View and chat in your groups', style: TextStyle(color: _isDarkMode ? Colors.black : Colors.indigo[700])),
                        onTap: () {
                          // TODO: Navigate to groups screen
                        },
                      ),
                    ),
                    // Add more group cards if needed
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ContactsScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String title, int pageIndex) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          pageIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.ease,
        );
        setState(() {
          _currentPage = pageIndex;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _currentPage == pageIndex
                    ? Colors.orange
                    : (_isDarkMode ? Colors.white : const Color.fromARGB(179, 10, 10, 10)),
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Container(
              height: 3,
              width: 100,
              decoration: BoxDecoration(
                color: _currentPage == pageIndex ? Colors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
