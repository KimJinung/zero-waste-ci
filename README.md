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
### [현황 및 문제 제기]
현재 운영 중인 온프레미스 젠킨스 환경은 14개의 노드를 팀별로 고정 할당(1~N개)하여 운영 중이다. 하지만 2026년 3월 기준, 특정 팀은 빌드 큐 정체로 리소스 부족을 겪는 반면, 다른 팀의 노드는 장시간 유휴(Idle) 상태를 유지하는 자원 불균형(Resource Imbalance) 현상이 심화되고 있다.

### [원인 분석: 환경 종속성으로 인한 자원 사일로(Silo)화]
이러한 비효율의 근본 원인은 팀별로 상이한 OS 벤더, 패키지 버전 등에 따른 **'환경 종속성'**에 있다. 특히 레거시 Android 빌드 등 특정 프로젝트는 과거 버전의 OS 환경이 필수적이라 해당 팀에 전용 노드를 할당할 수밖에 없었다. 문제는 이러한 빌드 발생 빈도가 낮음에도 불구하고, 환경 유지를 위해 고정 자원을 계속 점유하여 전체 인프라 가동률을 저해한다는 점이다.

### [해결 전략: Zero-Waste CI 구축]
위 문제를 극복하기 위해 하드웨어 리소스와 빌드 환경을 분리하는 컨테이너 기반 에이전트 환경을 설계했다. 모든 빌드 디펜던시를 Docker 이미지로 격리하여 호스트 머신의 의존성을 제거했다. 이를 통해 모든 팀이 **공유 리소스 풀(Shared Resource Pool)**을 활용하게 함으로써, 필요할 때만 특정 OS 환경을 컨테이너로 띄워 빌드하고 리소스를 즉시 반환하는 탄력적이고 효율적인 CI 인프라를 구현했다.
