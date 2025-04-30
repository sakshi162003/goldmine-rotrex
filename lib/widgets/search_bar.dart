import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;

  const SearchBar({
    super.key,
    this.onSearchTap,
    this.onFilterTap,
  });

  @override
  State<SearchBar> createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar> {
  Color searchIconColor = Colors.grey;
  Color filterIconColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search House, Apartment, etc',
        prefixIcon: InkWell(
          onTap: () {
            setState(() => searchIconColor = Colors.brown);
            if (widget.onSearchTap != null) {
              widget.onSearchTap!();
            }
          },
          child: Icon(Icons.search, color: searchIconColor),
        ),
        suffixIcon: InkWell(
          onTap: () {
            setState(() => filterIconColor = Colors.brown);
            if (widget.onFilterTap != null) {
              widget.onFilterTap!();
            }
          },
          child: Icon(Icons.filter_list, color: filterIconColor),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
