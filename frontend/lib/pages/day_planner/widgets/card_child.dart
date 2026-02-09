import 'package:flutter/material.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';

class CardChild extends StatefulWidget {
  final PlanBlock block;
  final bool isDragging;
  final bool ofSeqList;
  final int index;
  final Function(int index)? onDelete;
  final Function onInfoTap;
  const CardChild(
      {super.key,
      required this.block,
      this.isDragging = false,
      this.ofSeqList = false,
      required this.index,
      this.onDelete,
      required this.onInfoTap});

  @override
  State<CardChild> createState() => _CardChildState();
}

class _CardChildState extends State<CardChild> {
  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final theme = Theme.of(context);
    final Color borderColor = widget.isDragging
        ? Colors.grey.shade300
        : block.type == BlockType.attraction
            ? Colors.amber.withOpacity(0.6)
            : Colors.purple.withOpacity(0.4);
    final Color textColor = widget.isDragging
        ? Colors.grey
        : block.type == BlockType.attraction
            ? Colors.amber.shade800
            : Colors.purple.shade400;
    final Color backgroundColor = widget.isDragging
        ? Colors.grey.withOpacity(0.5)
        : block.type == BlockType.attraction
            ? Colors.amber.withOpacity(0.2)
            : Colors.purple.withOpacity(0.2);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            block.type == BlockType.attraction
                ? Icons.attractions_outlined
                : Icons.hotel_outlined,
            size: 22,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              block.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
            ),
          ),
          InkWell(
            onTap: () => widget.onInfoTap(),
            child: Icon(
              Icons.info_outline_rounded,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          if (widget.ofSeqList) ...[
            ReorderableDragStartListener(
              index: widget.index,
              child: Icon(
                Icons.drag_handle,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                widget.onDelete?.call(widget.index);
              },
              child: Icon(
                Icons.close_rounded,
                color: textColor,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
