enum PreferenceKey {
  currentHouseId,
  isProUserForDebug,

  /// チュートリアル全般を表示するかどうか
  shouldShowNewHouseTutorial,

  /// チュートリアルのうち、最初の家事登録後のチュートリアルを表示したかどうか
  hasShownFirstHouseWorkTutorial,

  /// チュートリアルのうち、最初の家事ログ記録後のチュートリアルを表示したかどうか
  hasShownFirstWorkLogTutorial,
  workLogCountForAppReviewRequest,
  hasRequestedAppReviewWhenOver30WorkLogs,
  hasRequestedReviewWhenOver100WorkLogs,
  hasRequestedReviewForAnalysisView,
}
