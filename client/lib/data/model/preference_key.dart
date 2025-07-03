enum PreferenceKey {
  currentHouseId,
  isProUserForDebug,

  /// チュートリアルのうち、家事ログ登録方法のチュートリアルを表示するかどうか
  shouldShowHowToRegisterWorkLogsTutorial,

  /// チュートリアルのうち、家事ログの分析の確認方法のチュートリアルを表示するかどうか
  shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
  workLogCountForAppReviewRequest,
  hasRequestedAppReviewWhenOver30WorkLogs,
  hasRequestedReviewWhenOver100WorkLogs,
  hasRequestedReviewForAnalysisView,
}
