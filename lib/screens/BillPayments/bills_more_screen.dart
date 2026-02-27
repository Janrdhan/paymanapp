import 'package:flutter/material.dart';

class BillsMoreScreen extends StatelessWidget {
  const BillsMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bills & recharges",
          style: TextStyle(color: Colors.black),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "HELP",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _myBillsCard(),
            const SizedBox(height: 20),

            _sectionTitle("Suggested"),
            _grid([
              _item(Icons.bolt, "Electricity\nbill"),
              _item(Icons.credit_card, "Credit\ncard", badge: "Popular"),
              _item(Icons.local_gas_station, "FASTag\nrecharge"),
              _item(Icons.phone_android, "Mobile\nrecharge"),
            ]),

            _sectionTitle("Telecom & travel"),
            _grid([
              _item(Icons.phone_android, "Mobile\nrecharge"),
              _item(Icons.local_gas_station, "FASTag\nrecharge"),
              _item(Icons.sim_card, "Mobile\npostpaid"),
              _item(Icons.satellite_alt, "DTH\nrecharge", badge: "New"),
              _item(Icons.wifi, "Broadband\nbill"),
              _item(Icons.phone, "Landline\nbill"),
              _item(Icons.tv, "Cable\nTV"),
              _item(Icons.train, "Metro"),
              _item(Icons.ev_station, "EV\nrecharge"),
            ]),

            _sectionTitle("Finance"),
            _grid([
              _item(Icons.credit_card, "Credit\ncard", badge: "Popular"),
              _item(Icons.account_balance_wallet, "Loan\nrepayment"),
              _item(Icons.verified_user, "LIC /\ninsurance"),
              _item(Icons.calendar_month, "Recurring\ndeposit"),
            ]),

            _sectionTitle("Utilities"),
            _grid([
              _item(Icons.bolt, "Electricity\nbill"),
              _item(Icons.propane, "LPG\ncylinder"),
              _item(Icons.water_drop, "Water\nbill"),
              _item(Icons.gas_meter, "Piped\ngas"),
            ]),
          ],
        ),
      ),
    );
  }

  // ---------- Widgets ----------

  Widget _myBillsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "My bills",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _grid(List<Widget> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 18,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: items,
    );
  }

  Widget _item(IconData icon, String text, {String? badge}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Icon(icon, size: 26),
            ),
            if (badge != null)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badge == "Popular"
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
