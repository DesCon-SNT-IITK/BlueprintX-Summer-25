import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About DesCon App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 16),
              const Text(
                'The DesCon App is a innovative tool designed for the Design and Construction Society (DesCon) to assist architects, engineers, and builders. This application allows users to enhance blueprints using advanced image processing techniques and recognize text from construction documents with cutting-edge machine learning. Developed as of July 23, 2025, it aims to streamline design and construction workflows, fostering collaboration and precision.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 24),
              const Text(
                'Project Name: BluePrintX',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mentors',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 16),
              _buildMemberCard('Pushpender', 'Mentor', 'Provided guidance on project direction and technical oversight.', 'assets/img.png'),
              _buildMemberCard('Bhavnoor Singh', 'Mentor', 'Offered expertise in software development and debugging.', 'assets/img_2.png'),
              _buildMemberCard('Shashank Katiyar', 'Mentor', 'Supported with design insights and project management.', 'assets/img_1.png'),
              const SizedBox(height: 24),
              const Text(
                'Team Members',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 16),
              _buildMemberCard('Aditya Panwar', 'Lead Developer', 'Designed the core architecture and implemented camera integration.','assets/aditya.jpg'),
              _buildMemberCard('Jiya Agarwal', 'Image Processing Specialist', 'Enhanced blueprint processing algorithms.'),
              _buildMemberCard('Jayendra Singh', 'ML Engineer', 'Developed the text recognition feature.'),
              _buildMemberCard('Yanshika Singh', 'Image Processing Specialist', 'Enhanced blueprint processing algorithms.'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(String name, String role, String contribution, [String? imagePath]) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: imagePath != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
        )
            : const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(role, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(contribution, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
