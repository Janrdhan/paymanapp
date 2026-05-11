class BBPSCategoryConfig {
  final String category;
  final List<Map<String, String>> fields;

  BBPSCategoryConfig({required this.category, required this.fields});
}

final Map<String, BBPSCategoryConfig> bbpsConfig = {
  "FASTag": BBPSCategoryConfig(
    category: "FASTag",
    fields: [
      {"key": "vehicleNumber", "label": "Vehicle Number"}
    ],
  ), 

  "Municipal Services": BBPSCategoryConfig(
    category: "Municipal Services",
    fields: [
      {"key": "house", "label": "House Number"}
    ],
  ),

  "DTH": BBPSCategoryConfig(
    category: "DTH",
    fields: [
      {"key": "number", "label": "Registered Mobile Number / Viewing Card Number"}
    ],
  ),

  "Mobile Postpaid": BBPSCategoryConfig(
    category: "Mobile Postpaid",
    fields: [
      {"key": "mobile", "label": "Mobile Number"}
    ],
  ),


"Mobile Prepaid": BBPSCategoryConfig(
    category: "Mobile Prepaid",
    fields: [
      {"key": "mobile", "label": "Mobile Number"}
    ],
  ),


  "Credit Card": BBPSCategoryConfig( 
    category: "Credit Card",
    fields: [
      {"key": "last4", "label": "Last 4 Digits"},
      {"key": "mobile", "label": "Registered Mobile Number"}
    ],
  ),

  "Electricity": BBPSCategoryConfig(
    category: "Electricity",
    fields: [
      {"key": "serviceNumber", "label": "Service Number"}
    ],
  ),

  "Insurance": BBPSCategoryConfig(
    category: "Insurance",
    fields: [
      {"key": "mobile", "label": "Mobile Number"},
      {"key": "date", "label": "Date of Birth (DD/MM/YYYY)"},
      {"key": "email", "label": "Email Address"},
      {"key": "policy", "label": "Policy Number"}
    ]
  ),
};