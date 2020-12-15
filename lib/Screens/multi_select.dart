import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
class MultiContactPage extends StatefulWidget {
  static const String id = "MultiSelect_contacts";
  MultiContactPage({Key key, this.title}) : super(key: key);

  final String title;
  final String reloadLabel = 'Reload!';
  final String fireLabel = 'Select';
  final Color floatingButtonColor = Colors.red;
  final IconData reloadIcon = Icons.refresh;
  final IconData fireIcon = Icons.filter_center_focus;

  @override
  _MultiContactPageState createState() => new _MultiContactPageState(
    floatingButtonLabel: this.fireLabel,
    icon: this.fireIcon,
    floatingButtonColor: this.floatingButtonColor,
  );
}

class _MultiContactPageState extends State<MultiContactPage> {
  List<Contact> _contacts = new List<Contact>();
  List<CustomContact> _uiCustomContacts = List<CustomContact>();
  List<CustomContact> _allContacts = List<CustomContact>();
  bool _isLoading = false;
  bool _isSelectedContactsView = false;
  String floatingButtonLabel;
  Color floatingButtonColor;
  IconData icon;

  _MultiContactPageState({
    this.floatingButtonLabel,
    this.icon,
    this.floatingButtonColor,
  });

  @override
  void initState() {
    super.initState();
    getPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Contact Multi Select"),
      ),
      body: !_isLoading
          ? Container(
        child: ListView.builder(
          itemCount: _uiCustomContacts?.length,
          itemBuilder: (BuildContext context, int index) {
            CustomContact _contact = _uiCustomContacts[index];
            var _phonesList = _contact.contact.phones.toList();

            return _buildListTile(_contact, _phonesList);
          },
        ),
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
      floatingActionButton: new FloatingActionButton.extended(
        backgroundColor: floatingButtonColor,
        onPressed: _onSubmit,
        icon: Icon(icon),
        label: Text(floatingButtonLabel),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _onSubmit() {
    setState(() {
      if (!_isSelectedContactsView) {
        _uiCustomContacts =
            _allContacts.where((contact) => contact.isChecked == true).toList();
        _isSelectedContactsView = true;
        _restateFloatingButton(
          widget.reloadLabel,
          Icons.refresh,
          Colors.green,
        );
      } else {
        _uiCustomContacts = _allContacts;
        _isSelectedContactsView = false;
        _restateFloatingButton(
          widget.fireLabel,
          Icons.filter_center_focus,
          Colors.red,
        );
      }
    });
  }

  ListTile _buildListTile(CustomContact c, List<Item> list) {
    return ListTile(
      leading: (c.contact.avatar != null)
          ? CircleAvatar(backgroundImage: MemoryImage(c.contact.avatar))
          : CircleAvatar(
        child: Text(
            (c.contact.displayName[0] +
                c.contact.displayName[1].toUpperCase()),
            style: TextStyle(color: Colors.white)),
      ),
      title: Text(c.contact.displayName ?? ""),
      subtitle: list.length >= 1 && list[0]?.value != null
          ? Text(list[0].value)
          : Text(''),
      trailing: Checkbox(
          activeColor: Colors.green,
          value: c.isChecked,
          onChanged: (bool value) {
            setState(() {
              c.isChecked = value;
            });
          }),
    );
  }

  void _restateFloatingButton(String label, IconData icon, Color color) {
    floatingButtonLabel = label;
    icon = icon;
    floatingButtonColor = color;
  }

  refreshContacts() async {
    setState(() {
      _isLoading = true;
    });
    var contacts = await ContactsService.getContacts();
    _populateContacts(contacts);
  }

  void _populateContacts(Iterable<Contact> contacts) {
    _contacts = contacts.where((item) => item.displayName != null).toList();
    _contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
    _allContacts =
        _contacts.map((contact) => CustomContact(contact: contact)).toList();
    setState(() {
      _uiCustomContacts = _allContacts;
      _isLoading = false;
    });
  }

  getPermissions() async {
    if (await Permission.contacts.request().isGranted) {
      refreshContacts();
    }else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Oops!'),
          content: const Text('Looks like permission to read contacts is not granted.'),
          actions: <Widget>[
            FlatButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
  // Future<bool> getContactsPermission() =>
  //     SimplePermissions.requestPermission(Permission.ReadContacts);
}

class CustomContact {
  final Contact contact;
  bool isChecked;

  CustomContact({
    this.contact,
    this.isChecked = false,
  });
}