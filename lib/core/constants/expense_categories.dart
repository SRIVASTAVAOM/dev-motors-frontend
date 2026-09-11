class ExpenseCategories {
  static const List<Map<String, String>> categories = [
    {
      "name": "Fuel",
      "subtitle": "Customer Test Drive, Travel, Source to Destination",
      "icon": "local_gas_station",
    },
    {
      "name": "Vehicle Maintenance",
      "subtitle": "Lath Work, Outside Work, Washing, Gen Repair, Puncture Repair",
      "icon": "car_repair",
    },
    {
      "name": "Office Supplies",
      "subtitle": "Stationery, Consumables",
      "icon": "inventory_2",
    },
    {
      "name": "Hospitality & Refreshments",
      "subtitle": "Tea, Snacks, Lunch, Dinner",
      "icon": "coffee",
    },
    {
      "name": "Travel & Conveyance",
      "subtitle": "Field Staff, Vehicle Transit, Local Transport, Toll (Source to Destination)",
      "icon": "commute",
    },
    {
      "name": "Staff Meals & Overtime Food",
      "subtitle": "Late night stock delivery, workshop overtime, employee dinner/lunch",
      "icon": "restaurant",
    },
    {
      "name": "Marketing & Promotional Events",
      "subtitle": "Banners, canopies, promotional flyers, local mall display setup",
      "icon": "campaign",
    },
    {
      "name": "Spot Incentives",
      "subtitle": "Instant staff/spot cash rewards & incentives",
      "icon": "military_tech",
    },
    {
      "name": "Miscellaneous",
      "subtitle": "Emergency petty cash & general workshop expenses",
      "icon": "more_horiz",
    },
  ];

  static List<String> get names => categories.map((c) => c["name"]!).toList();
}
