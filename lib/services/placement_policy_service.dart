import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/college_model.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/offer_model.dart';

/// Enforces college placement policies on job applications.
class PlacementPolicyService {
  static final _db = FirebaseFirestore.instance;

  /// Fetches the college's placement policy. Falls back to defaults.
  static Future<PlacementPolicy> getPolicy(String? collegeId) async {
    if (collegeId == null || collegeId.isEmpty) return PlacementPolicy();
    try {
      final doc = await _db.collection('colleges').doc(collegeId).get();
      if (doc.exists) {
        final college = CollegeModel.fromMap(doc.data()!, doc.id);
        return college.policy;
      }
    } catch (_) {}
    return PlacementPolicy();
  }

  /// Returns the tier of a job based on its CTC and the college policy.
  static String getJobTier(double ctcLpa, PlacementPolicy policy) {
    return policy.classifyTier(ctcLpa);
  }

  /// Checks if a student can apply to a job given the placement policy.
  /// Returns null if eligible, or a rejection reason string.
  static Future<String?> checkEligibility({
    required UserModel student,
    required JobModel job,
  }) async {
    final policy = await getPolicy(student.collegeId);

    // 1. CGPA check (job-level)
    if (job.requiredCgpa > 0 && (student.cgpa ?? 0) < job.requiredCgpa) {
      return 'Minimum CGPA of ${job.requiredCgpa} required. You have ${student.cgpa ?? 0}.';
    }

    // 2. College-level minimum CGPA
    if (policy.minCgpa > 0 && (student.cgpa ?? 0) < policy.minCgpa) {
      return 'College policy requires minimum CGPA of ${policy.minCgpa}.';
    }

    // 3. Branch check
    if (job.branchEligibility != null && job.branchEligibility!.isNotEmpty) {
      final allowed = job.branchEligibility!
          .split(',')
          .map((b) => b.trim().toLowerCase())
          .where((b) => b.isNotEmpty)
          .toList();
      if (allowed.isNotEmpty &&
          student.branch != null &&
          student.branch!.isNotEmpty &&
          !allowed.contains(student.branch!.toLowerCase())) {
        return 'Your branch (${student.branch}) is not eligible.';
      }
    }

    // 4. Active backlog check
    if ((student.activeBacklogs ?? 0) > policy.allowedActiveBacklogs) {
      return 'You have ${student.activeBacklogs} active backlogs. Max allowed: ${policy.allowedActiveBacklogs}.';
    }

    // 5. Job deadline check
    if (job.isExpired) {
      return 'Application deadline has passed.';
    }

    // 6. Opted-out check
    if (student.placementStatus == 'opted_out') {
      return 'You have opted out of placements.';
    }

    // 7. Max offers check
    if (policy.maxOffers > 0 && student.offersReceived >= policy.maxOffers) {
      return 'You have already received the maximum allowed offers (${policy.maxOffers}).';
    }

    // 8. Dream company blocking
    if (policy.blockAfterDream && student.placementStatus == 'placed') {
      // Check if student has accepted a Dream+ tier offer
      final acceptedOffers = await _db
          .collection('offers')
          .where('studentId', isEqualTo: student.id)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in acceptedOffers.docs) {
        final offer = OfferModel.fromMap(doc.data(), doc.id);
        final acceptedTier = policy.classifyTier(offer.ctcLpa);
        final jobTier = policy.classifyTier(job.ctcLpa);

        if (acceptedTier == 'Dream' || acceptedTier == 'Super Dream') {
          // Already placed in Dream+ → can only apply to Super Dream
          if (jobTier == 'Normal') {
            return 'You are placed in a $acceptedTier company. Cannot apply to Normal tier jobs.';
          }
          if (acceptedTier == 'Super Dream') {
            return 'You are placed in a Super Dream company. Further applications are blocked.';
          }
        }
      }
    }

    return null; // Eligible!
  }

  /// Returns all policy violations as a list (for admin view).
  static Future<List<String>> getViolations(UserModel student, PlacementPolicy policy) async {
    final violations = <String>[];
    if (policy.minCgpa > 0 && (student.cgpa ?? 0) < policy.minCgpa) {
      violations.add('CGPA below ${policy.minCgpa}');
    }
    if ((student.activeBacklogs ?? 0) > policy.allowedActiveBacklogs) {
      violations.add('${student.activeBacklogs} active backlogs (max: ${policy.allowedActiveBacklogs})');
    }
    if (policy.minAttendance > 0 && (student.attendance ?? 0) < policy.minAttendance) {
      violations.add('Attendance ${student.attendance}% (min: ${policy.minAttendance}%)');
    }
    return violations;
  }
}
