import 'package:flutter/material.dart';

import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/pages/day_planner/models/day_plan.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';

import 'package:travel_app/pages/day_planner/services/day_plan_service.dart';

class CurrPlanProvider extends ChangeNotifier {
  final PlaceModel location;
  final BlockList _blocks;
  final String tripId;
  final DayPlanService dayPlanService;
  DayPlan? savedPlan;
  List<PlanBlock>? editingSeq;
  bool isLoading = false;
  bool isEditing = false;
  String error = '';
  bool isDirty = false;
  int selectedDay;
  TextEditingController planTitleController = TextEditingController();

  BlockList get currPlan => _blocks;

  String? get validationMessage {
    if (editingSeq == null || editingSeq!.length <= 1) {
      return 'Add at least two places to create a day plan';
    }

    if (planTitleController.text.trim().isEmpty) {
      return 'Please enter a plan title';
    }

    return validAction;
  }

  String? get validAction {
    for (int i = 0; i < editingSeq!.length - 1; i++) {
      if (editingSeq![i].placeId == editingSeq![i + 1].placeId) {
        return 'Same place cannot be visited consecutively';
      }
    }
    return null;
  }

  CurrPlanProvider({
    required this.tripId,
    required this.location,
    required this.dayPlanService,
    this.savedPlan,
  })  : _blocks = BlockList.fromPlaceModel(location),
        selectedDay = savedPlan == null ? 1 : savedPlan.day {
    toggleEditing();
  }

  void onPlanTitleChanged(String value) {
    planTitleController.text = value;
    if (!isDirty) {
      isDirty = true;
      notifyListeners();
    }
  }

  void clearEditingSeq() {
    if (isEditing) editingSeq = [];
    isDirty = true;
    notifyListeners();
  }

  void toggleEditing() {
    isEditing = !isEditing;
    editingSeq = savedPlan == null ? [] : savedPlan!.sequence.toList();
    isDirty = false;
    planTitleController.text = savedPlan == null ? '' : savedPlan!.planTitle;
    notifyListeners();
  }

  void addBlockAtIndex(PlanBlock block, int index) {
    if (!isEditing || editingSeq == null) return;
    List<PlanBlock> originalSeq = editingSeq!.toList();
    editingSeq!.insert(index, block);
    if (validAction != null) {
      handleError(validAction!);
      editingSeq = originalSeq;
    } else {
      isDirty = true;
      notifyListeners();
    }
  }

  void removeAtIndex(int index) {
    if (!isEditing || editingSeq == null) return;
    editingSeq!.removeAt(index);
    isDirty = true;
    notifyListeners();
  }

  void onReorder(int oldIndex, int newIndex) {
    if (!isEditing || editingSeq == null) return;
    List<PlanBlock> originalSeq = editingSeq!.toList();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final block = editingSeq!.removeAt(oldIndex);
    editingSeq!.insert(newIndex, block);
    if (validAction != null) {
      handleError(validAction!);
      editingSeq = originalSeq;
    } else {
      isDirty = true;
      notifyListeners();
    }
  }

  void saveSequence() async {
    if (isEditing) {
      if (isDirty) {
        if (validationMessage != null) {
          handleError(validationMessage!);
          return;
        } else {
          isLoading = true;
          notifyListeners();
          DayPlan planToSave;
          if (savedPlan == null) {
            planToSave = DayPlan(
              id: '',
              planTitle: planTitleController.text,
              tripId: tripId,
              locationId: location.placeId,
              day: selectedDay,
              sequence: editingSeq!,
              createdBy: AddedBy(userId: '', userName: ''),
              isStarred: false,
            );
          } else {
            planToSave = savedPlan!.copyWith(
              planTitle: planTitleController.text,
              sequence: editingSeq!,
              day: selectedDay,
            );
          }
          try {
            savedPlan = await dayPlanService.saveDayPlan(planToSave);
            isLoading = false;
            toggleEditing();
          } catch (e) {
            isLoading = false;
            handleError(e.toString());
          }
        }
      } else {
        toggleEditing();
      }
    }
  }

  void handleError(String message) {
    error = message;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      error = '';
    });
  }

  void clearError() {
    error = '';
  }

  void setPlanForEdit(DayPlan plan) {
    savedPlan = plan;
    selectedDay = plan.day;
    planTitleController.text = plan.planTitle;
    editingSeq = plan.sequence.toList();
    isEditing = true;
    notifyListeners();
  }
}
