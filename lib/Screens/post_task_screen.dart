import 'package:flutter/material.dart';

class PostTaskScreen extends StatelessWidget {
  const PostTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 350,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://via.placeholder.com/400x350/1DBF73/FFFFFF?text=Background'), // Network Placeholder image
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: '''What\'s next on your to-do list ?''',
                                border: InputBorder.none,
                                icon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Describe your task.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Review your offers.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Get things done.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Handle Post Task button press
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DBF73),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Post Task',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Post any task in seconds',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCategoryButton(context, Icons.delivery_dining, 'Delivery'),
                  _buildCategoryButton(context, Icons.handyman, 'Handyman'),
                  _buildCategoryButton(context, Icons.format_paint, 'Painting'),
                  _buildCategoryButton(context, Icons.cleaning_services, 'Cleaning'),
                  _buildCategoryButton(context, Icons.local_shipping, 'Hauling'),
                  _buildCategoryButton(context, Icons.computer, 'Computer'),
                  _buildCategoryButton(context, Icons.fitness_center, 'Heavy Lifting'),
                  _buildCategoryButton(context, Icons.camera_alt, 'Photography'),
                  _buildCategoryButton(context, Icons.people, 'Event Staffing'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, IconData icon, String label) {
    return OutlinedButton(
      onPressed: () {
        // Handle category button press
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.blueGrey),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ],
      ),
    );
  }
} 