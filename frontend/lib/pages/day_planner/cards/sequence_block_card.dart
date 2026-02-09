import 'package:flutter/material.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';
import 'package:travel_app/pages/day_planner/widgets/card_child.dart';

class SequenceBlockCard extends StatefulWidget {
  final PlanBlock block;
  final int index;
  final Function(int index) onRemove;
  final Function(PlanBlock newBlock, int index) onAdded;
  final Function onInfoTap;
  const SequenceBlockCard(
      {super.key,
      required this.block,
      required this.index,
      required this.onRemove,
      required this.onAdded,
      required this.onInfoTap});

  @override
  State<SequenceBlockCard> createState() => _SequenceBlockCardState();
}

class _SequenceBlockCardState extends State<SequenceBlockCard> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: DragTarget<PlanBlock>(
            onMove: (_) {
              if (!_isHovering) {
                setState(() {
                  _isHovering = true;
                });
              }
            },
            onLeave: (_) {
              setState(() {
                _isHovering = false;
              });
            },
            onAcceptWithDetails: (details) {
              setState(() {
                _isHovering = false;
              });
              widget.onAdded(details.data, widget.index);
            },
            builder: (context, accepted, rejected) {
              return SizedBox(
                width: double.infinity,
                height: _isHovering ? 40 : 12,
              );
            },
          ),
        ),
        CardChild(
          block: widget.block,
          index: widget.index,
          ofSeqList: true,
          onDelete: widget.onRemove,
          onInfoTap: widget.onInfoTap,
        ),
      ],
    );
  }
}
