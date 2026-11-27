import 'tone_sandhi_rules.dart';
import 'text_normalizer_zh.dart';

class CedictPinyinEngine {
  static final Map<String, String> _dictionary = {
    // Dai tu & Dai tu so huu
    '你': 'nǐ',
    '我': 'wǒ',
    '他': 'tā',
    '她': 'tā',
    '它': 'tā',
    '们': 'men',
    '您': 'nín',
    '这': 'zhè',
    '那': 'nà',
    '哪': 'nǎ',
    '谁': 'shéi',
    '什么': 'shénme',
    '怎么': 'zěnme',
    '多少': 'duōshao',
    '几': 'jǐ',

    // So dem
    '一': 'yī',
    '二': 'èr',
    '三': 'sān',
    '四': 'sì',
    '五': 'wǔ',
    '六': 'liù',
    '七': 'qī',
    '八': 'bā',
    '九': 'jiǔ',
    '十': 'shí',
    '百': 'bǎi',
    '千': 'qiān',
    '零': 'líng',

    // Danh tu pho bien
    '人': 'rén',
    '朋友': 'péngyou',
    '老师': 'lǎoshī',
    '学生': 'xuésheng',
    '中国': 'zhōngguó',
    '北京': 'běijīng',
    '汉语': 'hànyǔ',
    '字': 'zì',
    '书': 'shū',
    '水': 'shuǐ',
    '茶': 'chá',
    '米饭': 'mǐfàn',
    '苹果': 'píngguǒ',
    '钱': 'qián',
    '飞机': 'fēijī',
    '出租车': 'chūzūchē',
    '学校': 'xuéxiào',
    '饭馆': 'fànguǎn',
    '商店': 'shāngdiàn',
    '医院': 'yīyuàn',
    '火车站': 'huǒchēzhàn',
    '家': 'jiā',
    '爸爸': 'bàba',
    '妈妈': 'māma',
    '儿子': 'érzi',
    '女儿': 'nǚér',
    '猫': 'māo',
    '狗': 'gǒu',
    '今天': 'jīntiān',
    '明天': 'míngtiān',
    '昨天': 'zuótiān',
    '上午': 'shàngwǔ',
    '中午': 'zhōngwǔ',
    '下午': 'xiàwǔ',
    '年': 'nián',
    '月': 'yuè',
    '日': 'rì',
    '号': 'hào',
    '星期': 'xīngqī',
    '点': 'diǎn',
    '分钟': 'fēnzhōng',
    '名字': 'míngzi',
    '东西': 'dōngxi',
    '岁': 'suì',
    '天气': 'tiānqì',

    // Dong tu
    '是': 'shì',
    '有': 'yǒu',
    '看': 'kàn',
    '听': 'tīng',
    '说': 'shuō',
    '读': 'dú',
    '写': 'xiě',
    '见': 'jiàn',
    '叫': 'jiào',
    '买': 'mǎi',
    '开': 'kāi',
    '坐': 'zuò',
    '住': 'zhù',
    '吃': 'chī',
    '喝': 'hē',
    '睡': 'shuì',
    '觉': 'jiào',
    '睡觉': 'shuìjiào',
    '打电话': 'dǎdiànhuà',
    '工作': 'gōngzuò',
    '学习': 'xuéxí',
    '爱': 'ài',
    '喜欢': 'xǐhuan',
    '想': 'xiǎng',
    '认识': 'rènshi',
    '会': 'huì',
    '能': 'néng',
    '可以': 'kěyǐ',
    '请': 'qǐng',
    '来': 'lái',
    '去': 'qù',
    '回': 'huí',

    // Tinh tu
    '好': 'hǎo',
    '多': 'duō',
    '少': 'shǎo',
    '冷': 'lěng',
    '热': 'rè',
    '高兴': 'gāoxìng',
    '漂亮': 'piàoliang',
    '小': 'xiǎo',
    '大': 'dà',

    // Pho tu, Gioi tu, Lien tu
    '不': 'bù',
    '没': 'méi',
    '很': 'hěn',
    '太': 'tài',
    '都': 'dōu',
    '在': 'zài',
    '和': 'hé',
    '的': 'de',
    '了': 'le',
    '吗': 'ma',
    '呢': 'ne',
  };

  static String lookupPinyin(String hanzi) {
    return _dictionary[hanzi] ?? '';
  }

  static List<String> convertToPinyinList(String sentence, {bool applySandhi = true}) {
    final clean = TextNormalizerZh.normalize(sentence);
    final hanziList = <String>[];
    final pinyinList = <String>[];

    int i = 0;
    while (i < clean.length) {
      if (clean[i] == ' ') {
        i++;
        continue;
      }

      // Tra tu ghep 3 ky tu truoc neu co
      if (i + 3 <= clean.length) {
        final triple = clean.substring(i, i + 3);
        if (_dictionary.containsKey(triple)) {
          final pinyins = _dictionary[triple]!.split(' ');
          for (int k = 0; k < 3; k++) {
            hanziList.add(triple[k]);
            pinyinList.add(k < pinyins.length ? pinyins[k] : _dictionary[triple[k]] ?? '');
          }
          i += 3;
          continue;
        }
      }

      // Tra tu ghep 2 ky tu
      if (i + 2 <= clean.length) {
        final pair = clean.substring(i, i + 2);
        if (_dictionary.containsKey(pair)) {
          final pinyins = _dictionary[pair]!.split(' ');
          if (pinyins.length == 2) {
            hanziList.add(pair[0]);
            pinyinList.add(pinyins[0]);
            hanziList.add(pair[1]);
            pinyinList.add(pinyins[1]);
          } else {
            hanziList.add(pair[0]);
            pinyinList.add(_dictionary[pair[0]] ?? pair[0]);
            hanziList.add(pair[1]);
            pinyinList.add(_dictionary[pair[1]] ?? pair[1]);
          }
          i += 2;
          continue;
        }
      }

      // Tra tu don
      final single = clean[i];
      hanziList.add(single);
      pinyinList.add(_dictionary[single] ?? single);
      i++;
    }

    if (applySandhi) {
      return ToneSandhiRules.applyToneSandhi(hanziList, pinyinList);
    }
    return pinyinList;
  }
}
