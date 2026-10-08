import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chopel_app/models/learning_content.dart';

final learningContentProvider = FutureProvider<List<LearningContent>>((ref) async {
  // Hardcoded learning content so it's always available
  final categories = {
    'ציר אנטומיה': [
      {'title': 'יסודות מבנה הגוף', 'file': 'doc_21.pdf'},
      {'title': 'מערכת הנשימה', 'file': 'doc_19.pdf'},
      {'title': 'מערכת ההובלה', 'file': 'doc_18.pdf'},
      {'title': 'מערכת העצבים', 'file': 'doc_20.pdf'},
    ],
    'ציר טראומה': [
      {'title': 'עצירת דימומים', 'file': 'doc_26.pdf'},
      {'title': 'קינימטיקה בטראומה', 'file': 'doc_33.pdf'},
      {'title': 'פגיעות שונות', 'file': 'doc_27.pdf'},
      {'title': 'תגובת קרב ודחק', 'file': 'doc_34.pdf'},
      {'title': 'אוכלוסיות מיוחדות', 'file': 'doc_2.pdf'},
      {'title': 'שמירה על עמש"צ', 'file': 'doc_31.pdf'},
      {'title': 'פרוצדורות', 'file': 'doc_17.pdf'},
      {'title': 'פגיעות AR', 'file': 'doc_28.pdf'},
      {'title': 'פגיעות הלם', 'file': 'doc_16.pdf'},
      {'title': 'סקר שניוני והטיפול המתמשך', 'file': 'doc_32.pdf'},
      {'title': 'טיפול בכאב', 'file': 'doc_10.pdf'},
      {'title': 'גישה ורידית', 'file': 'doc_23.pdf'},
      {'title': 'אירוע רב נפגעים', 'file': 'doc_22.pdf'},
      {'title': 'חבישות וקיבועים', 'file': 'doc_7.pdf'},
      {'title': 'מבוא לטראומה', 'file': 'doc_25.pdf'},
      {'title': 'שלבים XC', 'file': 'doc_30.pdf'},
      {'title': 'הערכה וניהול נתיב אוויר', 'file': 'doc_6.pdf'},
      {'title': 'פגיעות אקלים חם', 'file': 'doc_14.pdf'},
      {'title': 'פגיעות אקלים קר', 'file': 'doc_15.pdf'},
      {'title': 'שלבים ARE', 'file': 'doc_29.pdf'},
      {'title': 'החייאת בקרת נזקים בשדה', 'file': 'doc_24.pdf'},
      {'title': 'סמכת טיפול בפצוע - XCARE', 'file': 'doc_13.pdf'},
    ],
    'ציר החייאה': [
      {'title': 'החייאת מבוגר', 'file': 'doc_5.pdf'},
      {'title': 'החייאת ילדים ותינוקות', 'file': 'doc_4.pdf'},
      {'title': 'סילוק גוף זר', 'file': 'doc_8.pdf'},
      {'title': 'מכשירי החייאה', 'file': 'doc_11.pdf'},
    ],
    'ציר שגרה': [
      {'title': 'חשיפה לדם', 'file': 'doc_9.pdf'},
      {'title': 'גישה ורידית ושאיבות דם', 'file': 'doc_3.pdf'},
    ],
  };

  List<LearningContent> allDocs = [];
  categories.forEach((category, items) {
    for (int i = 0; i < items.length; i++) {
      allDocs.add(LearningContent(
        id: '\${category}-\${i}',
        title: items[i]['title']!,
        type: 'PDF',
        category: category,
        url: 'https://ffnrvjoswyphsduvmhbe.supabase.co/storage/v1/object/public/learning_materials/${items[i]['file']}',
      ));
    }
  });

  return allDocs;
});
