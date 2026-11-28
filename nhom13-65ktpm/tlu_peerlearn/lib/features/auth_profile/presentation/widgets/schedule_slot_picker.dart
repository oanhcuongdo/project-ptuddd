import 'package:flutter/material.dart';
import '../../domain/program_registration.dart';

class ScheduleSlotPicker extends StatelessWidget {
  final Set<int> selectedSlots;
  final ValueChanged<int> onToggleSlot;

  const ScheduleSlotPicker({
    super.key,
    required this.selectedSlots,
    required this.onToggleSlot,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khung lịch rảnh trong tuần (${selectedSlots.length}/21 buổi)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.8),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Buổi',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                ...ProgramRegistration.dayLabels.map(
                  (d) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            for (int session = 0; session < 3; session++)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Text(
                      ProgramRegistration.sessionLabels[session],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  for (int day = 0; day < 7; day++)
                    _buildCell(day * 3 + session, colorScheme),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(int slotIndex, ColorScheme colorScheme) {
    final isSelected = selectedSlots.contains(slotIndex);
    return InkWell(
      key: ValueKey('slot_$slotIndex'),
      onTap: () => onToggleSlot(slotIndex),
      child: Container(
        height: 36,
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        child: Center(
          child: isSelected
              ? Icon(Icons.check, size: 18, color: colorScheme.primary)
              : null,
        ),
      ),
    );
  }
}

