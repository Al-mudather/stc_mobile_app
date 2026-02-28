import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:stc_training/features/course/controller/offline_courses_controller.dart';
import 'package:stc_training/helper/app_colors.dart';
import 'package:stc_training/helper/directory_path.dart';
import 'package:stc_training/helper/enumerations.dart';
import 'package:stc_training/helper/methods.dart';
import 'package:stc_training/routes/route_helper.dart';
import 'package:stc_training/services/CRUD/offline_video_model.dart';
import 'package:stc_training/utils/custom_btn_util.dart';
import 'package:stc_training/utils/custom_text_util.dart';

class OfflineChapterItemContentComp extends StatefulWidget {
  const OfflineChapterItemContentComp({super.key, required this.video});

  final OfflineVideoModel? video;

  @override
  State<OfflineChapterItemContentComp> createState() =>
      _OfflineChapterItemContentCompState();
}

class _OfflineChapterItemContentCompState
    extends State<OfflineChapterItemContentComp> {
  bool fileExists = false;

  final OfflineCoursesController offlineCoursectl =
      Get.find<OfflineCoursesController>();

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    final storagePath = widget.video?.storagePath;
    if (storagePath == null || storagePath.isEmpty) return;
    final exists = await File(storagePath).exists();
    if (mounted) {
      setState(() => fileExists = exists);
    }
  }

  Future<void> _playOfflineVideo() async {
    try {
      Get.toNamed(Routehelper.GoToOfflineVideoPlayerPage(
          localVideoPath: widget.video?.storagePath ?? ''));
    } catch (e) {
      LOG_THE_DEBUG_DATA(messag: e, type: 'e');
    }
  }

  Future<void> _deleteVideo() async {
    final videoUuid = widget.video?.videoUuid;
    final videoPk = widget.video?.pk;

    try {
      if (videoPk != null) {
        await offlineCoursectl.removeVideo(videoId: videoPk);
      }

      if (videoUuid != null && videoUuid.isNotEmpty) {
        final appDocPath =
            await DirectoryPath().getApplicationDocumentsStoragePath();
        final dirPath = "$appDocPath/video/$videoUuid/";
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }

      if (mounted) setState(() => fileExists = false);

      SEND_a_message_to_the_user(
        message: "Video deleted successfully",
        messageLable: "Success",
        backgroundColor: AppColors.successLight,
      );
    } catch (e) {
      SEND_a_message_to_the_user(
        message: "Could not delete the video: $e",
        messageLable: "Error",
        backgroundColor: AppColors.errorDark,
      );
    }
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: "Delete Video?",
      middleText: "This will remove the downloaded video from your device.",
      barrierDismissible: false,
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.errorDark,
      onCancel: () {},
      onConfirm: () async {
        Get.back();
        await _deleteVideo();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: fileExists ? _playOfflineVideo : null,
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top:
                BorderSide(color: AppColors.brown.withOpacity(0.5), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/svgs/opened_lock.svg'),
            const SizedBox(width: 5),
            Expanded(
              child: CustomTextUtil(
                text1: "${widget.video?.title ?? ''}",
                fontSize1: 14,
                fontWeight1: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            CustomBtnUtil(
              btnTitle: "",
              btnType: BtnTypes.filledIcon,
              onClicked: () => _playOfflineVideo(),
              icon: Icon(
                Icons.play_arrow,
                color: AppColors.successDark,
              ),
            ),
            if (fileExists)
              CustomBtnUtil(
                btnTitle: '',
                btnType: BtnTypes.filledIcon,
                icon: Icon(
                  Icons.delete_forever,
                  color: AppColors.errorDark,
                ),
                onClicked: _confirmDelete,
              ),
          ],
        ),
      ),
    );
  }
}
