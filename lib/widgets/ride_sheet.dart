import 'package:flutter/material.dart';

Widget buildRideSheet(BuildContext context) {
  return DraggableScrollableSheet(
    initialChildSize: 0.18,
    minChildSize: 0.18,
    maxChildSize: 0.8,
    builder: (context, scrollController) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconOption(Icons.directions_car, 'UberX', Colors.blue, () {}),
                _buildIconOption(Icons.car_rental, 'Uber Black', Colors.black, () {}),
                _buildIconOption(Icons.airport_shuttle, 'Uber XL', Colors.green, () {}),
              ],
            ),
            const SizedBox(height: 30),
            _buildInputField('الاسم الكامل', Icons.person, TextInputType.text),
            const SizedBox(height: 15),
            _buildInputField('رقم الهاتف', Icons.phone, TextInputType.phone),
            const SizedBox(height: 15),
            _buildDateField(context, 'تاريخ الرحلة', Icons.calendar_today),
            const SizedBox(height: 15),
            _buildInputField('ملاحظات إضافية', Icons.note, TextInputType.multiline),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'تأكيد الحجز',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildIconOption(IconData icon, String label, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 40, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}

Widget _buildInputField(String hintText, IconData icon, TextInputType keyboardType) {
  return TextField(
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue),
      ),
    ),
    keyboardType: keyboardType,
  );
}

Widget _buildDateField(BuildContext context, String hintText, IconData icon) {
  return TextField(
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue),
      ),
    ),
    readOnly: true,
    onTap: () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        // يمكن تحديث الحالة أو عرض التاريخ المحدد كما ترغب
      }
    },
  );
}
