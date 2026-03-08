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
현재 운영 중인 온프레미스 Jenkins 환경은 약 20대 이상의 노드를 팀별로 **정적 할당(Static Allocation)**하여 운영하고 있다. 이로 인해 특정 팀은 빌드 큐 정체로 리소스 부족을 겪는 반면, 다른 팀의 노드는 장시간 유휴(Idle) 상태를 유지하는 자원 불균형(Resource Imbalance) 현상이 심화되고 있다.

조직 내 복잡한 이해관계로 인해 인프라 전반을 개선하기는 어려운 환경이지만, '완벽함은 없어도 비효율은 끊임없이 개선할 수 있다'는 신념 아래 개인 프로젝트를 시작했다. 이 프로젝트가 유사한 인프라 병목 현상을 겪는 엔지니어들에게 실질적인 인사이트를 제공하기를 바란다.

### [Root Cause: Resource Silos driven by Environment Dependency]
이러한 비효율의 근본 원인은 팀별로 상이한 OS 벤더, 패키지 버전 등 **환경 종속성(Environment Dependency)**에 기인한 **자원 사일로(Resource Silo)**화에 있다.

특히 레거시 Android 빌드와 같이 특정 구 버전 OS 환경이 필수적인 프로젝트의 경우, 환경 격리가 어려워 전용 노드를 고정 할당할 수밖에 없는 구조이다. 이러한 문제로 노드를 정적 할당한 것으로 추측된다. 그러나 이러한 프로젝트들은 빌드 빈도가 낮음에도 불구하고, 환경 유지를 위해 고정 자원을 상시 점유함으로써 전체 인프라의 가동률(Utilization)을 저해하는 주요 원인이 된다.


### [Solution Strategy: Implementation of Zero-Waste CI]
위 문제를 해결하기 위해 하드웨어 리소스와 빌드 환경을 분리하는 컨테이너 기반 에이전트(Containerized Agent) 아키텍처를 설계했다.

- Dependency Isolation: 모든 빌드 디펜던시를 Docker 이미지로 격리하여 호스트 머신과의 의존성을 완전히 제거했다.

- Elastic Resource Pool: 고정 할당 방식에서 벗어나 모든 팀이 공유하는 **탄력적 리소스 풀(Shared Resource Pool)**을 구축했다.

- On-Demand Lifecycle: 빌드 요청 시점에 필요한 OS 환경을 컨테이너로 프로비저닝하고, 빌드 종료 즉시 리소스를 반환함으로써 전체 컴퓨팅 리소스를 남김없이 활용할 수 있는 Zero-Waste CI 인프라를 구현했다.
