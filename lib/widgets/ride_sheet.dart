import 'package:flutter/material.dart';

Widget buildRideSheet(
    BuildContext context, {
      required VoidCallback onConfirm,
      required TextEditingController departureController,
      required TextEditingController passengersController,
      required TextEditingController notesController,
    }) {
  return DraggableScrollableSheet(
    initialChildSize: 0.17,
    minChildSize: 0.17,
    maxChildSize: 0.6,
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
            // خيارات نوع الرحلة (مثال)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconOption(
                    Icons.directions_car, 'UberX', Colors.blue, () {}),
                _buildIconOption(
                    Icons.car_rental, 'Uber Black', Colors.black, () {}),
                _buildIconOption(
                    Icons.airport_shuttle, 'Uber XL', Colors.green, () {}),
              ],
            ),
            const SizedBox(height: 30),
            // حقل عدد الركاب
            _buildInputField(
              "عدد الركاب",
              Icons.people,
              TextInputType.number,
              controller: passengersController,
            ),
            const SizedBox(height: 15),
            // حقل تاريخ الرحلة
            _buildDateField(
              context,
              "تاريخ الرحلة",
              Icons.calendar_today,
              controller: departureController,
            ),
            const SizedBox(height: 15),
            // حقل الملاحظات
            _buildInputField(
              "ملاحظات إضافية",
              Icons.note,
              TextInputType.multiline,
              controller: notesController,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onConfirm,
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

/// حقل إدخال نصي مع إمكانية تمرير Controller (إن وجد)
Widget _buildInputField(String hintText, IconData icon, TextInputType keyboardType, {TextEditingController? controller}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    ),
    keyboardType: keyboardType,
  );
}

/// حقل تاريخ يتم اختياره من خلال DatePicker ويتم تحديث نصه بواسطة Controller
Widget _buildDateField(BuildContext context, String hintText, IconData icon, {required TextEditingController controller}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue),
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
        // تحويل التاريخ إلى صيغة ISO 8601 كما في البيانات
        controller.text = pickedDate.toUtc().toIso8601String();
      }
    },
  );
}

/// خيار أيقونة بسيط مع تسمية
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
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}
