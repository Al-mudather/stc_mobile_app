import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:stc_training/features/course/controller/offline_courses_controller.dart';
import 'package:stc_training/features/course/offline_my_courses_page.dart';
import 'package:stc_training/features/course/online_my_courses_page.dart';
import 'package:stc_training/helper/app_colors.dart';
import 'package:stc_training/utils/custom_text_util.dart';

class OnlineOfflineMyCoursesPage extends HookWidget {
  const OnlineOfflineMyCoursesPage({
    super.key,
    this.isPage = true,
  });

  final bool isPage;

  @override
  Widget build(BuildContext context) {
    final OfflineCoursesController offlineCoursectl =
        Get.find<OfflineCoursesController>();

    final tabController = useTabController(initialLength: 2);

    useEffect(() {
      offlineCoursectl.open();
      return () => offlineCoursectl.close();
    }, []);

    final tabBar = TabBar(
      controller: tabController,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.blacklight4,
      tabs: const [
        Tab(text: "Online"),
        Tab(text: "Offline"),
      ],
    );

    final tabBarView = TabBarView(
      controller: tabController,
      children: [
        OnlineMyCoursesPage(isPage: false),
        GetBuilder<OfflineCoursesController>(
          builder: (ctl) => OffLineMyCoursesPage(
            isPage: false,
            courses: ctl.courses,
          ),
        ),
      ],
    );

    if (!isPage) {
      return Column(
        children: [
          tabBar,
          Expanded(child: tabBarView),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: CustomTextUtil(
          text1: "My Courses",
          fontSize1: 18,
          fontWeight1: FontWeight.w800,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepBlack),
          onPressed: () => Get.back(),
        ),
        bottom: tabBar,
      ),
      body: tabBarView,
    );
  }
}
