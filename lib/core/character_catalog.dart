String titleCaseFolder(String value) => value
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
    .join(' ');

/// Tên các nhân vật ZZZ dùng để tạo cấu trúc folder ban đầu.
/// Khi game có nhân vật mới, chỉ cần bổ sung tên vào danh sách này.
const zzzCharacterFolders = <String>[
  'Anby Demara',
  'Anton Ivanov',
  'Astra Yao',
  'Asaba Harumasa',
  'Ben Bigger',
  'Billy Kid',
  'Burnice White',
  'Caesar King',
  'Corin Wickes',
  'Dialyn',
  'Ellen Joe',
  'Evelyn Chevalier',
  'Grace Howard',
  'Jane Doe',
  'Ju Fufu',
  'Koleda Belobog',
  'Lighter',
  'Lucia',
  'Lucy',
  'Lycaon',
  'Miyabi',
  'Nekomata',
  'Nicole Demara',
  'Orphie and Magus',
  'Pan Yinhu',
  'Piper Wheel',
  'Pulchra',
  'Qingyi',
  'Rina',
  'Roxy Ifrita Pryce',
  'Seed',
  'Seth Lowell',
  'Soldier 0 - Anby',
  'Soldier 11',
  'Soukaku',
  'Trigger',
  'Vivian',
  'Yanagi',
  'Yixuan',
  'Zhu Yuan',
];

/// Trang phục bổ sung theo danh sách Agent Outfits trên ZZZ Wiki.
/// Tên thư mục: `Tên nhân vật - Tên trang phục`.
const zzzSkinFolders = <String, List<String>>{
  'Astra Yao': ['Chandelier'],
  'Ellen Joe': ['On Campus'],
  'Jane Doe': ['Nocturne of Light'],
  'Lucy': ['Princess on Holiday'],
  'Miyabi': ['Dignified Blossom'],
  'Nicole Demara': ['Cunning Cutie'],
  'Pan Yinhu': ['Culinary Jewel'],
  'Vivian': ['Iris of the Shore'],
  'Yixuan': ['Trails of Ink'],
};

const zzzSkinAvatarAssets = <String, String>{
  'Astra Yao - Chandelier': 'assets/characters/astra_yao/chandelier.webp',
  'Ellen Joe - On Campus': 'assets/characters/ellen_joe/on_campus.webp',
  'Jane Doe - Nocturne of Light':
      'assets/characters/jane_doe/nocturne_of_light.webp',
  'Lucy - Princess on Holiday':
      'assets/characters/lucy/princess_on_holiday.webp',
  'Miyabi - Dignified Blossom':
      'assets/characters/miyabi/dignified_blossom.webp',
  'Nicole Demara - Cunning Cutie':
      'assets/characters/nicole_demara/cunning_cutie.webp',
  'Pan Yinhu - Culinary Jewel':
      'assets/characters/pan_yinhu/culinary_jewel.webp',
  'Vivian - Iris of the Shore':
      'assets/characters/vivian/iris_of_the_shore.webp',
  'Yixuan - Trails of Ink': 'assets/characters/yixuan/trails_of_ink.webp',
};

const zzzAvatarAssets = <String, String>{
  'Anby Demara': 'assets/characters/anby_demara/default.png',
  'Anton Ivanov': 'assets/characters/anton_ivanov/default.png',
  'Astra Yao': 'assets/characters/astra_yao/default.png',
  'Asaba Harumasa': 'assets/characters/asaba_harumasa/default.png',
  'Ben Bigger': 'assets/characters/ben_bigger/default.png',
  'Billy Kid': 'assets/characters/billy_kid/default.png',
  'Burnice White': 'assets/characters/burnice_white/default.png',
  'Caesar King': 'assets/characters/caesar_king/default.png',
  'Corin Wickes': 'assets/characters/corin_wickes/default.png',
  'Dialyn': 'assets/characters/dialyn/default.png',
  'Ellen Joe': 'assets/characters/ellen_joe/default.png',
  'Evelyn Chevalier': 'assets/characters/evelyn_chevalier/default.png',
  'Grace Howard': 'assets/characters/grace_howard/default.png',
  'Jane Doe': 'assets/characters/jane_doe/default.png',
  'Ju Fufu': 'assets/characters/ju_fufu/default.png',
  'Koleda Belobog': 'assets/characters/koleda_belobog/default.png',
  'Lighter': 'assets/characters/lighter/default.png',
  'Lucy': 'assets/characters/lucy/default.png',
  'Lucia': 'assets/characters/lucia/default.png',
  'Lycaon': 'assets/characters/lycaon/default.png',
  'Miyabi': 'assets/characters/miyabi/default.png',
  'Nekomata': 'assets/characters/nekomata/default.png',
  'Nicole Demara': 'assets/characters/nicole_demara/default.png',
  'Orphie and Magus': 'assets/characters/orphie_and_magus/default.png',
  'Pan Yinhu': 'assets/characters/pan_yinhu/default.png',
  'Piper Wheel': 'assets/characters/piper_wheel/default.png',
  'Pulchra': 'assets/characters/pulchra/default.png',
  'Qingyi': 'assets/characters/qingyi/default.png',
  'Rina': 'assets/characters/rina/default.png',
  'Roxy Ifrita Pryce': 'assets/characters/roxy_ifrita_pryce/default.png',
  'Seed': 'assets/characters/seed/default.png',
  'Seth Lowell': 'assets/characters/seth_lowell/default.png',
  'Soldier 0 - Anby': 'assets/characters/soldier_0_anby/default.png',
  'Soldier 11': 'assets/characters/soldier_11/default.png',
  'Soukaku': 'assets/characters/soukaku/default.png',
  'Trigger': 'assets/characters/trigger/default.png',
  'Vivian': 'assets/characters/vivian/default.png',
  'Yanagi': 'assets/characters/yanagi/default.png',
  'Yixuan': 'assets/characters/yixuan/default.png',
  'Zhu Yuan': 'assets/characters/zhu_yuan/default.png',
};
