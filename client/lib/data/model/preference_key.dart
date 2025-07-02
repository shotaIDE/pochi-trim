enum PreferenceKey {
  currentHouseId,
  isProUserForDebug,

  /// チュートリアル全般を表示するかどうか
  ///
  /// 新しい家に参加した時に表示するチュートリアル全般。
  shouldShowNewHouseTutorial,

  /// チュートリアルのうち、家事ログ登録方法のチュートリアルを表示したかどうか
  hasShownHowToRegisterWorkLogsTutorial,

  /// チュートリアルのうち、家事ログの分析の確認方法のチュートリアルを表示したかどうか
  hasShownHowToCheckWorkLogsAndAnalysisTutorial,
  workLogCountForAppReviewRequest,
  hasRequestedAppReviewWhenOver30WorkLogs,
  hasRequestedReviewWhenOver100WorkLogs,
  hasRequestedReviewForAnalysisView,
}
