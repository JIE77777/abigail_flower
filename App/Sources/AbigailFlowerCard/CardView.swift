import SwiftUI
import AppKit

struct CardView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var isFlowerHovered = false
    @State private var pageDraft: CountdownPageDraft?
    @State private var isOverviewPresented = false
    @State private var draftDateText = ""
    @State private var expandedOverviewCardIDs: Set<UUID> = []

    private let quotePanelHeight: CGFloat = 94

    private var themedDaysRemaining: Int {
        viewModel.content.daysRemaining < 0 ? 99 : viewModel.content.daysRemaining
    }

    private var theme: CardTheme {
        CardTheme.resolve(daysRemaining: themedDaysRemaining)
    }

    private var currentDateCard: (year: String, date: String, weekday: String) {
        dateCardParts(for: Date())
    }

    private var primaryEntries: [CardEntry] {
        viewModel.content.entries.filter { !isEasterEgg($0) }
    }

    private var easterEggLine: String? {
        viewModel.content.entries.first(where: isEasterEgg)?.lines.first
    }

    private var absoluteDaysRemaining: Int {
        abs(viewModel.content.daysRemaining)
    }

    private var countdownUnitText: String {
        if viewModel.content.daysRemaining == 0 {
            return "就是这一天"
        }
        return viewModel.content.daysRemaining < 0 ? "天前" : "天"
    }

    private var hasAnyOverlay: Bool {
        pageDraft != nil || isOverviewPresented
    }

    private var currentPageIndex: Int {
        (viewModel.pages.firstIndex(where: { $0.id == viewModel.currentPage.id }) ?? 0) + 1
    }

    private var visiblePageIndices: [Int] {
        Array(viewModel.pages.indices)
    }

    private var canDeleteDraft: Bool {
        guard let draft = pageDraft else { return false }
        return !draft.isNew && viewModel.canDeleteCurrentPage
    }

    private var canOpenDraftInNewCard: Bool {
        guard let draft = pageDraft else { return false }
        return !draft.isNew && viewModel.canDetachCurrentPage
    }

    private var isDraftDateInputValid: Bool {
        guard pageDraft != nil else { return true }
        return parsedDraftDate(from: draftDateText) != nil
    }

    private var draftDateHintText: String {
        if isDraftDateInputValid {
            return "可直接输入 20260831、2026-08-31；右侧可点选日期"
        }
        return "请输入有效日期，例如 2026-08-31"
    }

    var body: some View {
        ZStack {
            backgroundLayer
            mergeTargetRing
            decorativeFlower

            VStack(alignment: .leading, spacing: 10) {
                heroSection
                Spacer(minLength: 0)
                quoteBlock
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)

            if isOverviewPresented {
                pageOverviewOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
            }

            if pageDraft != nil {
                pageEditorOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topTrailing)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: hasAnyOverlay)
        .animation(.easeInOut(duration: 0.16), value: viewModel.isMergeTargetHighlighted)
        .opacity(viewModel.config.cardOpacity)
        .frame(width: viewModel.panelSize.width, height: viewModel.panelSize.height)
        .background(Color.clear)
        .contextMenu {
            Button("编辑倒计时") {
                openCurrentPageEditor()
            }
            Button("打开倒计时总览") {
                openOverview()
            }
            Button("偏好设置") {
                openPreferences()
            }
            Button("新建倒计时") {
                openNewPageEditor()
            }
            if viewModel.canDetachCurrentPage {
                Button("在新卡片打开") {
                    viewModel.openCurrentPageInNewCard()
                }
            }
            Divider()
            Button("找回全部卡片") {
                viewModel.revealAllCards()
            }
            Button("重置所有卡片位置") {
                viewModel.resetAllCardPositions()
            }
            Divider()
            if viewModel.canDeleteCurrentPage {
                Button("删除当前页", role: .destructive) {
                    viewModel.deleteCurrentPage()
                }
            }
            Divider()
            Button("换一句") {
                viewModel.reroll()
            }
            Button("刷新今天") {
                viewModel.reload(forceConfig: true)
            }
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 16) {
            countdownBlock
            Spacer(minLength: 0)
            dateColumn
        }
    }

    private var dateColumn: some View {
        currentDateBadge
            .frame(width: 88, alignment: .trailing)
            .padding(.top, 4)
    }

    private var pageSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(visiblePageIndices, id: \.self) { index in
                pageDot(for: index)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.35, perform: openOverview)
        .contextMenu {
            Button("打开倒计时总览") {
                openOverview()
            }
        }
        .help("点击页迹切换倒计时，拖出页迹可拆成新卡片")
    }

    private func pageDot(for index: Int) -> some View {
        let page = viewModel.pages[index]
        let isActive = index + 1 == currentPageIndex

        return Capsule()
            .fill(isActive ? theme.quoteAccent.opacity(0.72) : theme.quoteAccent.opacity(0.20))
            .frame(width: isActive ? 16 : 8, height: 8)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectPage(id: page.id)
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 6)
                    .onEnded { value in
                        guard viewModel.pages.count > 1 else { return }
                        guard abs(value.translation.width) > 6 || abs(value.translation.height) > 6 else { return }
                        viewModel.detachPage(page.id)
                    }
            )
            .help(viewModel.pages[index].title)
            .animation(.easeInOut(duration: 0.16), value: currentPageIndex)
    }

    private var embeddedRerollButton: some View {
        Button(action: viewModel.reroll) {
            ZStack {
                Circle()
                    .fill(theme.buttonFill.opacity(isFlowerHovered ? 1.0 : 0.86))
                    .frame(width: 34, height: 34)
                Circle()
                    .stroke(theme.buttonStroke, lineWidth: 1)
                    .frame(width: 34, height: 34)
                flowerImage
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
            .background(
                Circle()
                    .fill(Color.white.opacity(0.28))
            )
            .shadow(
                color: theme.buttonShadow.opacity(0.72),
                radius: 8,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help("换一句")
        .onHover { hovering in
            isFlowerHovered = hovering
        }
    }

    private var currentDateBadge: some View {
        VStack(spacing: 0) {
            Text(currentDateCard.year)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundColor(Color.white.opacity(0.96))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.48, green: 0.37, blue: 0.36).opacity(0.86),
                            Color(red: 0.40, green: 0.30, blue: 0.29).opacity(0.90),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 4) {
                Text(currentDateCard.date)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.7)
                    .foregroundColor(Color(red: 0.34, green: 0.20, blue: 0.19))

                Text(currentDateCard.weekday)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(0.8)
                    .foregroundColor(theme.badgeText)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, 8)
            .background(Color(red: 1.0, green: 0.985, blue: 0.97).opacity(0.78))
        }
        .frame(width: 88)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.82, green: 0.71, blue: 0.67).opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.33, green: 0.19, blue: 0.17).opacity(0.07), radius: 12, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(count: 2, perform: openCurrentPageEditor)
        .help("双击可编辑倒计时")
    }

    private var countdownBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                pageSwitcher

                Text(viewModel.content.title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.34, green: 0.20, blue: 0.19))
                    .tracking(0.7)
                    .padding(.leading, 2)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: openCurrentPageEditor)
                    .help("双击编辑倒计时")
            }

            if viewModel.content.daysRemaining == 0 {
                Text("今天")
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.10))
                    .tracking(-1.6)

                Text(countdownUnitText)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.unitColor)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(absoluteDaysRemaining)")
                        .font(.system(size: 92, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.10))
                        .tracking(-3.3)
                        .minimumScaleFactor(0.82)

                    Text(countdownUnitText)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.unitColor)
                        .padding(.bottom, 7)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .gesture(pageSwipeGesture)
    }

    private var quoteBlock: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(primaryEntries) { entry in
                    EntryView(entry: entry, accentColor: theme.quoteAccent)
                }

                if let eggLine = easterEggLine {
                    EggChip(text: eggLine, accentColor: theme.quoteAccent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Capsule()
                .fill(theme.quoteAccent.opacity(0.22))
                .frame(width: 1, height: 38)

            embeddedRerollButton
                .padding(.trailing, 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: quotePanelHeight, maxHeight: quotePanelHeight, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.quotePanelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.56),
                                    Color.white.opacity(0.02),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(theme.quotePanelStroke, lineWidth: 1)
                )
        )
        .shadow(color: Color(red: 0.33, green: 0.19, blue: 0.17).opacity(0.10), radius: 18, x: 0, y: 12)
        .clipped()
    }

    private var pageEditorOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.08))
                .onTapGesture(perform: closePageEditor)

            pageEditorPanel
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private var pageOverviewOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.05))
                .onTapGesture(perform: closeOverview)

            pageOverviewPanel
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var pageOverviewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("倒计时总览")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(Color(red: 0.30, green: 0.18, blue: 0.17))
                    Text("找回、切换和整理你的卡片")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.52, green: 0.37, blue: 0.34))
                }

                Spacer(minLength: 10)

                Button(action: closeOverview) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.45, green: 0.31, blue: 0.29))
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.56))
                        )
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.overviewCards) { card in
                        overviewCardSection(for: card)
                    }
                }
            }
            .frame(maxHeight: 236)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.createStandaloneCard()
                        closeOverview()
                    }) {
                        Text("新建倒计时")
                    }
                    .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))

                    Button(action: {
                        viewModel.revealAllCards()
                        closeOverview()
                    }) {
                        Text("找回全部卡片")
                    }
                    .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))
                }

                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.resetAllCardPositions()
                        closeOverview()
                    }) {
                        Text("重置位置")
                    }
                    .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))

                    Spacer(minLength: 0)

                    Button(action: closeOverview) {
                        Text("关闭")
                    }
                    .buttonStyle(EditorCapsuleButtonStyle(fill: theme.quoteAccent.opacity(0.18), stroke: theme.quoteAccent.opacity(0.24), text: Color(red: 0.37, green: 0.23, blue: 0.21)))
                }
            }
        }
        .padding(14)
        .frame(width: 296)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.96).opacity(0.96),
                            Color(red: 0.97, green: 0.93, blue: 0.90).opacity(0.94),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.56), lineWidth: 1)
                )
        )
        .shadow(color: Color(red: 0.33, green: 0.19, blue: 0.17).opacity(0.14), radius: 24, x: 0, y: 14)
    }

    private func overviewCardSection(for card: CountdownCardOverview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Button(action: {
                    viewModel.focusCard(card.id)
                    closeOverview()
                }) {
                    overviewCardRow(for: card)
                }
                .buttonStyle(.plain)

                if card.pageCount > 1 {
                    Button(action: {
                        toggleOverviewExpansion(for: card.id)
                    }) {
                        Image(systemName: expandedOverviewCardIDs.contains(card.id) ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.46, green: 0.32, blue: 0.30))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.60))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if expandedOverviewCardIDs.contains(card.id) && card.pageCount > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(card.pages) { page in
                        overviewPageRow(cardID: card.id, page: page)
                    }
                }
                .padding(.leading, 18)
            }
        }
    }

    private func overviewCardRow(for card: CountdownCardOverview) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Capsule()
                .fill(card.isCurrentWindow ? theme.quoteAccent.opacity(0.72) : theme.quoteAccent.opacity(0.18))
                .frame(width: card.isCurrentWindow ? 12 : 6, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.28, green: 0.17, blue: 0.16))
                    .lineLimit(1)

                Text("\(formattedDate(card.targetDate)) · \(remainingText(daysRemaining: card.daysRemaining))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.50, green: 0.35, blue: 0.32))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(card.pageCount == 1 ? "单卡" : "\(card.pageCount)页")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.49, green: 0.31, blue: 0.29))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.quoteAccent.opacity(0.10))
                    )

                if card.isFocused {
                    Text(card.isCurrentWindow ? "当前" : "聚焦")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.56, green: 0.38, blue: 0.34))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(card.isCurrentWindow ? Color.white.opacity(0.66) : Color.white.opacity(0.48))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            card.isCurrentWindow
                                ? theme.quoteAccent.opacity(0.22)
                                : Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.16),
                            lineWidth: 1
                        )
                )
        )
    }

    private func overviewPageRow(cardID: UUID, page: CountdownOverviewPage) -> some View {
        let canDetach = pageCount(for: cardID) > 1

        return HStack(spacing: 8) {
            Button(action: {
                viewModel.selectOverviewPage(cardID: cardID, pageID: page.id)
                closeOverview()
            }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(page.isSelected ? theme.quoteAccent.opacity(0.70) : theme.quoteAccent.opacity(0.20))
                        .frame(width: 7, height: 7)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(page.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.31, green: 0.19, blue: 0.18))
                            .lineLimit(1)

                        Text("\(formattedDate(page.targetDate)) · \(remainingText(daysRemaining: page.daysRemaining))")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.52, green: 0.37, blue: 0.34))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            Button(action: {
                viewModel.detachOverviewPage(cardID: cardID, pageID: page.id)
                closeOverview()
            }) {
                Text("抽出")
            }
            .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))
            .opacity(canDetach ? 1.0 : 0.0)
            .disabled(!canDetach)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(page.isSelected ? 0.60 : 0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.quoteAccent.opacity(page.isSelected ? 0.18 : 0.10), lineWidth: 1)
                )
        )
    }

    private var pageEditorPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pageDraft?.isNew == true ? "新建倒计时" : "编辑倒计时")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(Color(red: 0.30, green: 0.18, blue: 0.17))
                    Text(pageDraft?.isNew == true ? "给新的倒计时起个名字" : "修改标签和目标日期")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.52, green: 0.37, blue: 0.34))
                }

                Spacer(minLength: 10)

                Button(action: closePageEditor) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.45, green: 0.31, blue: 0.29))
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.56))
                        )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("标签")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.50, green: 0.35, blue: 0.32))
                    .tracking(0.5)
                TextField("给日期起个名字", text: draftTitleBinding)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.82))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.28), lineWidth: 1)
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("日期")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.50, green: 0.35, blue: 0.32))
                    .tracking(0.5)

                HStack(alignment: .center, spacing: 8) {
                    TextField("2026-08-31", text: draftDateTextBinding)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.82))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            isDraftDateInputValid
                                                ? Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.28)
                                                : Color(red: 0.76, green: 0.35, blue: 0.37).opacity(0.42),
                                            lineWidth: 1
                                        )
                                )
                        )

                    DatePicker(
                        "目标日期",
                        selection: draftDateBinding,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.76))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), lineWidth: 1)
                            )
                    )
                }

                Text(draftDateHintText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(
                        isDraftDateInputValid
                            ? Color(red: 0.52, green: 0.37, blue: 0.34)
                            : Color(red: 0.70, green: 0.35, blue: 0.37)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    if pageDraft?.isNew != true {
                        Button(action: openNewPageEditor) {
                            Text("新建倒计时")
                        }
                        .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))
                    }

                    if canOpenDraftInNewCard {
                        Button(action: openCurrentPageInNewCardFromEditor) {
                            Text("在新卡片打开")
                        }
                        .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))
                    }

                    if canDeleteDraft {
                        Button(role: .destructive, action: deleteCurrentPage) {
                            Text("删除")
                        }
                        .buttonStyle(EditorCapsuleButtonStyle(fill: Color(red: 0.63, green: 0.29, blue: 0.31).opacity(0.12), stroke: Color(red: 0.70, green: 0.35, blue: 0.37).opacity(0.28), text: Color(red: 0.57, green: 0.24, blue: 0.26)))
                    }
                }

                Spacer(minLength: 0)

                Button(action: closePageEditor) {
                    Text("取消")
                }
                .buttonStyle(EditorCapsuleButtonStyle(fill: Color.white.opacity(0.56), stroke: Color(red: 0.79, green: 0.67, blue: 0.63).opacity(0.24), text: Color(red: 0.44, green: 0.30, blue: 0.28)))

                Button(action: saveDraft) {
                    Text("保存")
                }
                .buttonStyle(EditorCapsuleButtonStyle(fill: theme.quoteAccent.opacity(0.18), stroke: theme.quoteAccent.opacity(0.24), text: Color(red: 0.37, green: 0.23, blue: 0.21)))
                .disabled(!isDraftDateInputValid)
                .opacity(isDraftDateInputValid ? 1.0 : 0.55)
            }
        }
        .padding(14)
        .frame(width: 318)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.96).opacity(0.96),
                            Color(red: 0.97, green: 0.93, blue: 0.90).opacity(0.94),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.56), lineWidth: 1)
                )
        )
        .shadow(color: Color(red: 0.33, green: 0.19, blue: 0.17).opacity(0.14), radius: 26, x: 0, y: 16)
    }

    private var draftTitleBinding: Binding<String> {
        Binding(
            get: { pageDraft?.title ?? "" },
            set: { newValue in
                updatePageDraft { $0.title = newValue }
            }
        )
    }

    private var draftDateBinding: Binding<Date> {
        Binding(
            get: { pageDraft?.targetDate ?? Date() },
            set: { newValue in
                updatePageDraft { $0.targetDate = newValue }
                syncDraftDateText(from: newValue)
            }
        )
    }

    private var draftDateTextBinding: Binding<String> {
        Binding(
            get: { draftDateText },
            set: { newValue in
                draftDateText = newValue
                if let parsed = parsedDraftDate(from: newValue) {
                    updatePageDraft { $0.targetDate = parsed }
                }
            }
        )
    }

    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.paperTop, theme.paperMid, theme.paperBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(theme.cardStroke, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.34), Color.white.opacity(0.04)],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 240
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.clear,
                                Color(red: 0.46, green: 0.31, blue: 0.26).opacity(0.04),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 20)
    }

    private var mergeTargetRing: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(theme.quoteAccent.opacity(viewModel.isMergeTargetHighlighted ? 0.56 : 0.0), lineWidth: 3)
            .padding(2)
            .allowsHitTesting(false)
    }

    private var decorativeFlower: some View {
        flowerImage
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 124, height: 124)
            .opacity(theme.watermarkOpacity)
            .offset(x: 118, y: 98)
            .allowsHitTesting(false)
    }

    private var flowerImage: Image {
        if let url = AbigailPaths.bundledFlowerIcon(), let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "sparkles")
    }

    private func dateCardParts(for date: Date) -> (year: String, date: String, weekday: String) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekdayText = weekdays[max(0, min(weekdays.count - 1, weekday - 1))]
        return (
            year: String(year),
            date: String(format: "%02d.%02d", month, day),
            weekday: weekdayText
        )
    }

    private func isEasterEgg(_ entry: CardEntry) -> Bool {
        entry.lines.first?.hasPrefix("隐藏彩蛋：") == true
    }

    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if value.translation.width <= -36 {
                    viewModel.selectNextPage()
                } else if value.translation.width >= 36 {
                    viewModel.selectPreviousPage()
                }
            }
    }

    private func formattedDate(_ date: Date) -> String {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d.%02d.%02d", components.year ?? 2026, components.month ?? 1, components.day ?? 1)
    }

    private func remainingText(daysRemaining: Int) -> String {
        if daysRemaining == 0 { return "今天" }
        if daysRemaining < 0 { return "\(abs(daysRemaining)) 天前" }
        return "\(daysRemaining) 天"
    }

    private func openCurrentPageEditor() {
        closeOverview()
        let draft = viewModel.beginEditingCurrentPage()
        pageDraft = draft
        syncDraftDateText(from: draft.targetDate)
    }

    private func openNewPageEditor() {
        closeOverview()
        let draft = viewModel.beginCreatingPage()
        pageDraft = draft
        syncDraftDateText(from: draft.targetDate)
    }

    private func openOverview() {
        pageDraft = nil
        draftDateText = ""
        isOverviewPresented = true
    }

    private func closeOverview() {
        isOverviewPresented = false
    }

    private func closePageEditor() {
        pageDraft = nil
        draftDateText = ""
    }

    private func openPreferences() {
        PreferencesWindowAction.show()
    }

    private func saveDraft() {
        guard pageDraft != nil, let parsedDate = parsedDraftDate(from: draftDateText) else { return }
        updatePageDraft { $0.targetDate = parsedDate }
        guard let normalizedDraft = pageDraft else { return }
        viewModel.savePage(from: normalizedDraft)
        pageDraft = nil
        draftDateText = ""
    }

    private func deleteCurrentPage() {
        viewModel.deleteCurrentPage()
        pageDraft = nil
        draftDateText = ""
    }

    private func openCurrentPageInNewCardFromEditor() {
        viewModel.openCurrentPageInNewCard()
        pageDraft = nil
        draftDateText = ""
    }

    private func toggleOverviewExpansion(for cardID: UUID) {
        if expandedOverviewCardIDs.contains(cardID) {
            expandedOverviewCardIDs.remove(cardID)
        } else {
            expandedOverviewCardIDs.insert(cardID)
        }
    }

    private func pageCount(for cardID: UUID) -> Int {
        viewModel.overviewCards.first(where: { $0.id == cardID })?.pageCount ?? 0
    }

    private func updatePageDraft(_ update: (inout CountdownPageDraft) -> Void) {
        guard var draft = pageDraft else { return }
        update(&draft)
        pageDraft = draft
    }

    private func syncDraftDateText(from date: Date) {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2026
        let month = components.month ?? 1
        let day = components.day ?? 1
        draftDateText = String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func parsedDraftDate(from raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let digitsOnly = trimmed.filter(\.isNumber)
        let values: [Int]

        if digitsOnly.count == 8 {
            values = [
                Int(digitsOnly.prefix(4)) ?? 0,
                Int(digitsOnly.dropFirst(4).prefix(2)) ?? 0,
                Int(digitsOnly.suffix(2)) ?? 0,
            ]
        } else {
            let parts = trimmed
                .split(whereSeparator: { !$0.isNumber })
                .compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            values = parts
        }

        let year = values[0]
        let month = values[1]
        let day = values[2]

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = year
        components.month = month
        components.day = day

        guard
            let date = components.calendar?.date(from: components),
            components.calendar?.component(.year, from: date) == year,
            components.calendar?.component(.month, from: date) == month,
            components.calendar?.component(.day, from: date) == day
        else {
            return nil
        }

        return components.calendar?.startOfDay(for: date)
    }
}

private struct EntryView: View {
    let entry: CardEntry
    let accentColor: Color

    var body: some View {
        if entry.lines.count > 1 {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(accentColor.opacity(0.72))
                    .frame(width: 3)

                ZStack(alignment: .topLeading) {
                    Text("“")
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundColor(accentColor.opacity(0.22))
                        .offset(x: -2, y: -8)

                    VStack(alignment: .leading, spacing: 6) {
                        if let first = entry.lines.first {
                            Text(first)
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                .italic()
                                .foregroundColor(Color(red: 0.28, green: 0.17, blue: 0.16))
                                .lineSpacing(1)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if entry.lines.count > 1 {
                            Text(entry.lines[1])
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.48, green: 0.34, blue: 0.31))
                                .lineSpacing(1)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.leading, 12)
                }
            }
        } else {
            if let first = entry.lines.first {
                Text(first)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.28, green: 0.17, blue: 0.16))
                    .lineSpacing(1)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct EggChip: View {
    let text: String
    let accentColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.53, green: 0.38, blue: 0.35))
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.10))
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.10), lineWidth: 1)
                    )
            )
    }
}

private struct EditorCapsuleButtonStyle: ButtonStyle {
    let fill: Color
    let stroke: Color
    let text: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(text)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(fill.opacity(configuration.isPressed ? 0.84 : 1.0))
                    .overlay(
                        Capsule()
                            .stroke(stroke, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

private struct CardTheme {
    let paperTop: Color
    let paperMid: Color
    let paperBottom: Color
    let badgeText: Color
    let buttonFill: Color
    let buttonStroke: Color
    let buttonShadow: Color
    let unitColor: Color
    let quoteAccent: Color
    let quotePanelFill: Color
    let quotePanelStroke: Color
    let cardStroke: Color
    let cardShadow: Color
    let watermarkOpacity: Double

    private static let milestoneDays: Set<Int> = [200, 160, 150, 120, 100, 60, 50, 30, 10, 7, 3, 1]

    static func resolve(daysRemaining: Int) -> CardTheme {
        if daysRemaining == 0 {
            return CardTheme(
                paperTop: Color(red: 0.99, green: 0.96, blue: 0.89),
                paperMid: Color(red: 0.97, green: 0.92, blue: 0.84),
                paperBottom: Color(red: 0.94, green: 0.88, blue: 0.79),
                badgeText: Color(red: 0.50, green: 0.35, blue: 0.22),
                buttonFill: Color.white.opacity(0.54),
                buttonStroke: Color(red: 0.79, green: 0.66, blue: 0.47).opacity(0.42),
                buttonShadow: Color(red: 0.57, green: 0.40, blue: 0.24).opacity(0.15),
                unitColor: Color(red: 0.58, green: 0.39, blue: 0.24),
                quoteAccent: Color(red: 0.79, green: 0.60, blue: 0.34),
                quotePanelFill: Color(red: 1.0, green: 0.98, blue: 0.94).opacity(0.76),
                quotePanelStroke: Color(red: 0.82, green: 0.69, blue: 0.47).opacity(0.24),
                cardStroke: Color.white.opacity(0.44),
                cardShadow: Color(red: 0.45, green: 0.30, blue: 0.18).opacity(0.17),
                watermarkOpacity: 0.06
            )
        }

        if daysRemaining <= 10 {
            return CardTheme(
                paperTop: Color(red: 0.98, green: 0.94, blue: 0.91),
                paperMid: Color(red: 0.95, green: 0.88, blue: 0.87),
                paperBottom: Color(red: 0.92, green: 0.82, blue: 0.83),
                badgeText: Color(red: 0.57, green: 0.31, blue: 0.34),
                buttonFill: Color.white.opacity(0.52),
                buttonStroke: Color(red: 0.78, green: 0.48, blue: 0.50).opacity(0.38),
                buttonShadow: Color(red: 0.55, green: 0.30, blue: 0.33).opacity(0.14),
                unitColor: Color(red: 0.57, green: 0.33, blue: 0.35),
                quoteAccent: Color(red: 0.77, green: 0.46, blue: 0.49),
                quotePanelFill: Color(red: 0.99, green: 0.96, blue: 0.95).opacity(0.74),
                quotePanelStroke: Color(red: 0.76, green: 0.52, blue: 0.53).opacity(0.22),
                cardStroke: Color.white.opacity(0.43),
                cardShadow: Color(red: 0.44, green: 0.24, blue: 0.27).opacity(0.16),
                watermarkOpacity: 0.06
            )
        }

        if milestoneDays.contains(daysRemaining) {
            return CardTheme(
                paperTop: Color(red: 0.99, green: 0.95, blue: 0.88),
                paperMid: Color(red: 0.96, green: 0.90, blue: 0.83),
                paperBottom: Color(red: 0.93, green: 0.85, blue: 0.78),
                badgeText: Color(red: 0.55, green: 0.37, blue: 0.22),
                buttonFill: Color.white.opacity(0.50),
                buttonStroke: Color(red: 0.79, green: 0.61, blue: 0.38).opacity(0.38),
                buttonShadow: Color(red: 0.55, green: 0.37, blue: 0.20).opacity(0.14),
                unitColor: Color(red: 0.58, green: 0.38, blue: 0.26),
                quoteAccent: Color(red: 0.79, green: 0.57, blue: 0.33),
                quotePanelFill: Color(red: 1.0, green: 0.98, blue: 0.93).opacity(0.75),
                quotePanelStroke: Color(red: 0.78, green: 0.59, blue: 0.37).opacity(0.24),
                cardStroke: Color.white.opacity(0.43),
                cardShadow: Color(red: 0.48, green: 0.33, blue: 0.19).opacity(0.16),
                watermarkOpacity: 0.06
            )
        }

        return CardTheme(
            paperTop: Color(red: 0.98, green: 0.95, blue: 0.90),
            paperMid: Color(red: 0.95, green: 0.90, blue: 0.86),
            paperBottom: Color(red: 0.91, green: 0.85, blue: 0.83),
            badgeText: Color(red: 0.51, green: 0.35, blue: 0.33),
            buttonFill: Color.white.opacity(0.46),
            buttonStroke: Color(red: 0.71, green: 0.56, blue: 0.52).opacity(0.40),
            buttonShadow: Color(red: 0.45, green: 0.27, blue: 0.23).opacity(0.12),
            unitColor: Color(red: 0.49, green: 0.31, blue: 0.29),
            quoteAccent: Color(red: 0.68, green: 0.52, blue: 0.49),
            quotePanelFill: Color(red: 1.0, green: 0.98, blue: 0.96).opacity(0.72),
            quotePanelStroke: Color(red: 0.74, green: 0.61, blue: 0.57).opacity(0.20),
            cardStroke: Color.white.opacity(0.44),
            cardShadow: Color(red: 0.36, green: 0.22, blue: 0.20).opacity(0.16),
            watermarkOpacity: 0.05
        )
    }
}
