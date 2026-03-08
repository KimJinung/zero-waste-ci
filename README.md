# zero-waste-ci

## Table of Contents

1. [Background & Problem](#background--problem)
2. [System Architecture](#system-architecture)
3. [Key Features](#key-features)
4. [Tech Stacks](#tech-stacks)
5. [Implementation Details](#implementation-details)
6. [Benchmarks (Comparison)](#benchmarks-comparison)
7. [How to Use](#how-to-use)

---

## Background & Problem
### [Current State & Problem Statement]
현재 운영 중인 온프레미스 Jenkins 환경은 약 20대 이상의 노드를 팀별로 **정적 할당(Static Allocation)**하여 운영하고 있다. 이로 인해 특정 팀은 빌드 큐 정체로 리소스 부족을 겪는 반면, 다른 팀의 노드는 장시간 유휴 상태를 유지하는 자원 불균형 현상이 심화되고 있다.

조직 내 복잡한 이해관계로 인해 인프라 전반을 개선하기는 어려운 환경이지만, '완벽함은 없어도 비효율은 끊임없이 개선할 수 있다'는 신념 아래 개인 프로젝트를 시작했다. 이 프로젝트가 유사한 인프라 병목 현상을 겪는 엔지니어들에게 실질적인 인사이트를 제공하기를 바란다.

### [Root Cause: Resource Silos driven by Environment Dependency]
이러한 비효율의 근본 원인은 팀별로 상이한 OS 벤더, 패키지 버전 등 환경 종속성에 기인한 자원 사일로화에 있다.

특히 레거시 Android 빌드와 같이 특정 구 버전 OS 환경이 필수적인 프로젝트의 경우, 환경 격리가 어려워 전용 노드를 고정 할당할 수밖에 없는 구조이다. 이러한 문제로 노드를 정적 할당한 것으로 추측된다. 그러나 이러한 프로젝트들은 빌드 빈도가 낮음에도 불구하고, 환경 유지를 위해 고정 자원을 상시 점유함으로써 전체 인프라의 가동률을 저해하는 주요 원인이 된다.


### [Solution Strategy: Implementation of Zero-Waste CI]
위 문제를 해결하기 위해 호스트의 물리적 리소스는 공유하되, 개별 빌드 환경은 컨테이너로 격리하는 Runtime Isolation 전략을 채택했다.

- Build-in-Container Execution
  - 호스트 머신에 직접 도구를 설치하는 대신, 빌드 스텝마다 필요한 패키지와 툴체인을 이미지 내에 설치한다. 이를 통해 단일 호스트 내에서 서로 다른 버전의 OS와 SDK(예: Yocto Project, AOSP)가 충돌 없이 공존할 수 있다.

- High-Density Resource Utilization
  - 팀별 전용 노드 대신 공용 노드 풀에서 컨테이너 기반으로 병렬 빌드를 수행하여, 유휴 자원을 최소화하고 인프라 밀도를 극대화한다.

---

## System Architecture
본 시스템은 인프라 효율화를 위한 워크플로우 아키텍처와 이를 지탱하는 기술 스택으로 구성된다. 운영 시나리오는 인프라 엔지니어와 사용자의 역할을 분리하여 운영 효율을 극대화한다.

### [Operating Scenario: Infrastructure as a Service]
1. Standardization (Infra Engineer)
    - 빌드 환경에 필수적인 코어 패키지만 포함된 Base Image를 구성하고 배포한다. 이는 전사 인프라의 보안 및 표준 규격을 준수한다.


2. Customization (Developer)
    - 개발자는 프로젝트 특성에 맞춰 Base Image를 Layering한 커스텀 이미지를 생성한다. 필요한 패키지 변경 사항은 코드로 관리하며 Pull Request를 통해 투명하게 검토된다.


3. Verification & Distribution (CI/CD Pipeline)
    - 새로운 환경 설정이 포함된 PR이 오픈되면, CI 서버에서 Smoke Test를 수행하여 런타임 안정성을 검증한다. 검증이 완료된 이미지는 Container Registry로 자동 푸시된다.


4. Execution (Jenkins Runtime)
    - 사용자는 Jenkins 파이프라인에서 검증된 이미지를 호출하여 빌드를 수행한다. 호스트 환경에 구애받지 않는 독립적인 빌드 런타임이 보장된다.

### [Architecture Overview]
위 시나리오를 구현하기 위해 호스트 리소스 공유 기반의 컨테이너 실행 구조를 다음과 같이 설계했다.
