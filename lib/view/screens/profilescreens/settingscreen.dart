import 'package:chat_app/view/constants/text.dart';
import 'package:flutter/material.dart';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff292929),
      appBar: AppBar(
        backgroundColor: Color(0xff292929),
        elevation: 0,
        title: Text(
          "Settings",
          style: Apptexts.titlestyle.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            color: Color(0xff3e3e3e),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _buildTile(Icons.notifications, "Custom Notification"),
          _buildSwitchTile(Icons.volume_up, "Mute Notification"),
          Divider(color: Color(0xff444444)),
          _buildTile(Icons.group_add, "Invite Friends"),
          _buildTile(Icons.group, "Joined Groups"),
          _buildSwitchTile(Icons.visibility, "Hide Chat History"),
          _buildSwitchTile(Icons.security, "Security"),
          _buildTile(Icons.help_outline, "Help Center"),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff9A9BB1)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Color(0xff9A9BB1),
        size: 16,
      ),
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(IconData icon, String title) {
    return SwitchListTile(
      value: false,
      onChanged: (_) {},
      activeColor: Colors.blueAccent,
      inactiveThumbColor: Colors.grey,
      secondary: Icon(icon, color: const Color(0xff9A9BB1)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}
