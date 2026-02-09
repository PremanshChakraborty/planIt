import 'package:flutter/material.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';
import 'package:travel_app/pages/day_planner/widgets/card_child.dart';

class AvailableBlockCard extends StatelessWidget {
  final PlanBlock block;
  final int index;
  final Function onInfoTap;

  const AvailableBlockCard(
      {super.key, required this.block, required this.index, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Draggable<PlanBlock>(
      data: block,
      feedback: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 20,
          child: CardChild(block: block,index: index,onInfoTap: onInfoTap,),
        ),
      ),
      childWhenDragging: CardChild(block: block, isDragging: true,index: index,onInfoTap: onInfoTap,),
      child: CardChild(block: block,index: index,onInfoTap: onInfoTap,),
    );
  }
}
