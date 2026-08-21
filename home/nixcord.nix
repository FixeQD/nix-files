{ ... }:
{
  programs.nixcord = {
    enable = true;

    discord.equicord.enable = true;

    config.plugins = {
      alwaysAnimate.enable = true;
      accountPanelServerProfile.enable = true;
      advancedPermissions.enable = true;
      alwaysExpandRoles.enable = true;
      anonymiseFileNames.enable = true;
      betterFolders.enable = true;
      betterRoleContext.enable = true;
      betterRoleDot.enable = true;
      betterSettings = {
        enable = true;
        disableFade = false;
      };
      betterUploadButton.enable = true;
      biggerStreamPreview.enable = true;
      blurNsfw.enable = true;
      callTimer = {
        enable = true;
        format = "human";
        showSeconds = true;
      };
      clearUrls.enable = true;
      clipUpload.enable = true;
      commandPalette = {
        enable = true;
        hotkey = [ "Control" "Shift" "P" ];
      };
      consoleJanitor.enable = true;
      consoleShortcuts.enable = true;
      copyEmojiMarkdown.enable = true;
      crashHandler.enable = true;
      customTimestamps.enable = true;
      dearrow.enable = true;
      decor.enable = true;
      disableCameras.enable = true;
      disableDeepLinks.enable = true;
      dontRoundMyTimestamps.enable = true;
      dragify = {
        enable = true;
        reuseExistingInvites = true;
      };
      equicordHelper.enable = true;
      equicordToolbox.enable = true;
      experiments.enable = true;
      expressionCloner.enable = true;
      f8Break.enable = true;
      fakeNitro.enable = true;
      fakeProfileThemes.enable = true;
      fixCodeblockGap.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      followVoiceUser.enable = true;
      forceOwnerCrown.enable = true;
      friendCodes.enable = true;
      friendInvites.enable = true;
      gameActivityToggle.enable = true;
      gitHubRepos.enable = true;
      hideMedia.enable = true;
      iLoveSpam.enable = true;
      imageLink.enable = true;
      imageZoom = {
        enable = true;
        nearestNeighbour = true;
        size = 263.14102564102564;
        square = true;
        zoom = 2.0153885129182645;
        zoomSpeed = 1.6711094875273982;
      };
      memberCount.enable = true;
      messageLatency.enable = true;
      messageLinkEmbeds.enable = true;
      messageLogger.enable = true;
      messageLoggerEnhanced = {
        enable = true;
        imageCacheDir = "/home/fixeq/.config/Equicord/MessageLoggerData/savedImages";
        logsDir = "/home/fixeq/.config/Equicord/MessageLoggerData";
      };
      messageTranslate = {
        confidenceRequirement = 0.8;
        targetLanguage = "pl";
      };
      moreCommands.enable = true;
      musicControls = {
        showSpotifyControls = true;
      };
      mutualGroupDms.enable = true;
      newPluginsManager.enable = true;
      noBlockedMessages.enable = true;
      noDevtoolsWarning.enable = true;
      noF1.enable = true;
      noOnboardingDelay.enable = true;
      noPendingCount.enable = true;
      noReplyMention.enable = true;
      noTrack.enable = true;
      noTypingAnimation.enable = true;
      onePingPerDm.enable = true;
      openInApp.enable = true;
      permissionsViewer.enable = true;
      pinDms = {
        enable = true;
        userBasedCategoryList = {
          "853621876551188490" = [ ];
        };
      };
      platformIndicators.enable = true;
      previewMessage.enable = true;
      questify = {
        enable = true;
        acknowledgedNotices = {
          quest-ban-warning-2026-08-07 = true;
        };
        allowChangingDangerousSettings = true;
        autoCompleteQuestTypes = {
          PLAY_ON_DESKTOP = true;
          PLAY_ON_XBOX = true;
          PLAY_ON_PLAYSTATION = true;
          PLAY_ACTIVITY = true;
          WATCH_VIDEO = true;
          WATCH_VIDEO_ON_MOBILE = true;
          ACHIEVEMENT_IN_ACTIVITY = true;
        };
        completeVideoQuestsQuicker = true;
        ignoredQuestIds = {
          questIDs = [ ];
          "853621876551188490" = [ ];
        };
        makeMobileVideoQuestsDesktopCompatible = true;
        preventVideoQuestsPausing = true;
        questButtonBadgeCount = 13;
        resumeInterruptedQuests = true;
      };
      quickReply.enable = true;
      randomVoice = {
        keybind = [ ];
      };
      reactErrorDecoder.enable = true;
      readAllNotificationsButton.enable = true;
      revealAllSpoilers.enable = true;
      reviewDb = {
        enable = true;
        reviewsDropdownState = true;
      };
      roleColorEverywhere.enable = true;
      searchFix.enable = true;
      sendTimestamps.enable = true;
      serverInfo.enable = true;
      settings = {
        enable = true;
        settingsLocation = "aboveActivity";
      };
      showConnections = {
        enable = true;
        iconSpacing = 0;
      };
      showHiddenChannels.enable = true;
      showHiddenThings.enable = true;
      showMeYourName = {
        enable = true;
        includedNames = "{friend, nick} [{display}] (@{user})";
        triggerNameRerender = true;
      };
      silentTyping.enable = true;
      sortFriends.enable = true;
      spotifyCrack.enable = true;
      spotifyShareCommands.enable = true;
      startupTimings.enable = true;
      streamerModeOnStream.enable = true;
      summaries = {
        summaryExpiryThresholdDays = 7.050176056338028;
      };
      superReactionTweaks.enable = true;
      supportHelper.enable = true;
      translate = {
        enable = true;
        receivedOutput = "pl";
        sentInput = "pl";
      };
      typingIndicator.enable = true;
      typingTweaks.enable = true;
      userMessagesPronouns.enable = true;
      userPfp.enable = true;
      usrbg.enable = true;
      validReply.enable = true;
      validUser.enable = true;
      vcNarrator = {
        voice = null;
      };
      viewIcons = {
        enable = true;
        format = "png";
      };
      viewRaw.enable = true;
      voiceDownload.enable = true;
      webKeybinds.enable = true;
      webRichPresence.enable = true;
      whoReacted.enable = true;
      youtubeAdblock.enable = true;
    };

    extraConfig.plugins = {
      BANger = {
        source = "https://i.imgur.com/wp5q52C.mp4";
      };
      betterFolders = {
        nestedFolders = { };
      };
      consoleJanitor = {
        disableNoisyLoggers = false;
      };
      equicordHelper = {
        noDefaultHangStatus = false;
        disableCreateDMButton = false;
        disableDMContextMenu = false;
      };
      experiments = {
        enableIsStaff = true;
      };
      fontLoader = {
        applyOnClodeBlocks = false;
      };
      fullVcpfp = {
        useServerProfileAvatars = false;
      };
      gitHubRepos = {
        showRepositoryTab = true;
        showInMiniProfile = true;
      };
      globalBadges = {
        showRa1ncord = true;
      };
      imageZoom = {
        showMetadata = true;
      };
      musicRichPresence = {
        showLastFmLogo = true;
      };
      noBlockedMessages = {
        ignoreBlockedMessages = false;
      };
      noMosaic = {
        mediaLayoutType = "STATIC";
      };
      permissionsViewer = {
        defaultPermissionsDropdownState = false;
      };
      pinDms = {
        dmSectioncollapsed = false;
      };
      questify = {
        disableQuestsDiscoveryTab = false;
        disableQuestsFetchingQuests = false;
        disableQuestsDirectMessagesTab = false;
        disableQuestsPageSponsoredBanner = false;
        disableQuestsPopupAboveAccountPanel = true;
        disableQuestsBadgeOnUserProfiles = false;
        disableQuestsGiftInventoryRelocationNotice = true;
        disableFriendsListActiveNowPromotion = true;
        disableMembersListActivelyPlayingIcon = true;
        makeMobileQuestsDesktopCompatible = true;
        completeVideoQuestsInBackground = false;
        completeGameQuestsInBackground = false;
        completeAchievementQuestsInBackground = false;
        questButtonUnclaimed = "both";
        questRewardIncludeRewardCode = true;
        questRewardIncludeNitroCode = true;
        questRewardIncludeCollectibles = true;
        questRewardIncludeInGame = true;
        questRewardIncludeOrbs = true;
        fetchingQuestsInterval = 2700;
        fetchingQuestsAlert = "discodo";
        fetchingQuestsAlertVolume = 100;
        restyleQuestsUnclaimed = 2842239;
        restyleQuestsClaimed = 6105983;
        restyleQuestsIgnored = 8334124;
        restyleQuestsExpired = 2368553;
        restyleQuestsGradient = "intense";
        restyleQuestsPreload = true;
        reorderQuests = "UNCLAIMED, CLAIMED, IGNORED, EXPIRED";
        ignoredQuestProfile = "private";
      };
      RPCStats = {
        statDisplay = 0;
        lastFMApiKey = "";
        RPCTitle = "RPCStats";
        assetURL = "";
      };
      showHiddenThings = {
        disableDiscoveryFilters = true;
        disableDisallowedDiscoveryFilters = true;
      };
      translate = {
        shavian = true;
        sitelen = true;
        target = "pl";
        toki = true;
        showChatBarButton = true;
      };
      userMessagesPronouns = {
        pronounSource = 0;
        showInProfile = true;
        showInMessages = true;
      };
    };
  };
}
