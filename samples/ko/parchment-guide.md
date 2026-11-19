---
title: Parchment 사용 안내서
tags: [예제, 시작하기]
aliases: [사용 안내서]
작성자: Parchment
버전: 1.1.1
읽기완료: false
---

# Parchment에 오신 것을 환영합니다

Parchment는 브라우저에서 실행되는 **로컬 우선 Markdown 및 일반 텍스트 리더**입니다. 이 예제에서는 Parchment가 표시할 수 있는 주요 문법을 소개합니다.

> [!tip] 이 예제 사용 방법
> 오른쪽의 “목차”를 사용하여 섹션 사이를 이동하세요. “태그”, “연결된 노트”, “백링크” 탭에서 예제 노트의 관계를 확인할 수 있습니다.

위 속성은 YAML Frontmatter에서 생성됩니다. 태그를 클릭하면 파일 트리를 필터링할 수 있습니다.

## 텍스트 서식

**굵게**, *기울임꼴*, ~~취소선~~, ==강조 표시==, ++삽입된 텍스트++, `인라인 코드`를 사용할 수 있습니다.

H~2~O는 아래 첨자, x^2^는 위 첨자를 사용합니다. :sparkles: :books: :rocket: 같은 이모지도 변환됩니다.

각주 예제입니다.[^read-only]

*[HTML]: HyperText Markup Language

[^read-only]: Parchment는 파일을 읽기 전용으로 열며 원본 문서를 수정하지 않습니다.

## 목록과 작업

- 순서 없는 목록
  - 중첩 항목 지원
- 다른 항목

1. 순서 있는 목록
2. 두 번째 단계

- [x] 이 예제 열기
- [ ] 이 작업 전환하기(상태는 브라우저에만 저장됨)
- [ ] 내 노트 폴더 열기

## 표

| 기능 | 단일 파일 | 폴더 |
| --- | :---: | :---: |
| Markdown 렌더링 | ✅ | ✅ |
| 상대 이미지와 링크 | — | ✅ |
| Wiki 링크와 포함 | — | ✅ |
| 전체 텍스트 검색 | — | ✅ |

## 코드와 수식

```js
const [handle] = await window.showOpenFilePicker();
const file = await handle.getFile();
console.log(await file.text());
```

인라인 수식: $E = mc^2$.

$$
\int_{0}^{1} x^2 \, dx = \frac{1}{3}
$$

## 다이어그램

```mermaid
flowchart LR
  A[파일 또는 폴더 선택] --> B{Markdown?}
  B -->|예| C[렌더링]
  B -->|아니요| D[일반 텍스트 유지]
  C --> E[읽기, 검색, 이동]
```

## 콜아웃

> [!note]
> 일반적인 참고 내용입니다.

> [!warning] 사용자 지정 제목
> 콜아웃 안에서도 **Markdown**을 사용할 수 있습니다.

> [!question]- 접을 수 있나요?
> 예. 유형 뒤에 `-`를 추가하면 기본적으로 접힌 상태가 됩니다.

## 노트 링크와 포함

[[linked-note]]를 열거나 [[linked-note#포함할 수 있는 섹션|연결된 노트의 섹션]]으로 이동하세요.

![[linked-note#포함할 수 있는 섹션]]

![[linked-note#^summary]]

## 이미지

![Parchment 로고](../../image/parchment-logo-transparent.png)

![[parchment-logo-transparent.png|96]]

## 다음 단계

1. **폴더 열기**를 선택하여 내 노트 폴더를 엽니다.
2. 왼쪽 사이드바에서 모든 노트를 검색합니다.
3. 설정에서 다른 언어, 색상 팔레트 또는 글꼴을 사용해 봅니다.

이 예제는 오프라인에서도 사용할 수 있습니다.
