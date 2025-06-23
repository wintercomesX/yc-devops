# Дипломная работа курса «DevOps-инженер с нуля» Кандала Кирилл

## Предисловие

В основной деректории находятся 3 ключевых скрипта.
1. deploy.sh - вызывает в корректной последовательности аналогичные скрипты дочерних директорий. Которые, в свою очередь, вызывают необходимые команды для развертывания компонентов сервиса.
2. destroy.sh - выполняет аналогичную функцию как и п.1., но разрушает сервис.
3. github_setup.sh - подготавливает файлы для работы с ci-cd сервиса и отдвет информацию по всем секретам которые необходимо внести для настройки Github Actions.

Файлы backend_backup.tf и app_backup.yaml используются для хранения временного стэйта конфигов. При вызове deploy.sh текущее состояние конфигов копируется в backup файлы, затем значения в конфигах меняются. При destroy.sh происходит обратный процесс, значение из backup файлов возвращаются в основные конфиги.

## Пошаговая инструкция по применению

```
#Разворачиваем сервис
bash deploy.sh 
``` 
```
#Подготовка к работе с github и получение секретов для настройки github actions
bash github_setup.sh
```
```
# Вносим изменения в конфиг проекта на github
# https://github.com/<your_github_name>/<repository_name>/settings/secrets/actions
```
```
#Разрушаем проект
bash deploy.sh 
```

## Результаты выполнения

## Шаг 1 (Поднятие бакета с terrafom.state)

![image](https://github.com/user-attachments/assets/a8ed13ec-5270-4d33-86d6-08031e7a594a)

![image](https://github.com/user-attachments/assets/d80f3c7e-423a-4af8-a9f8-474c2c4b5897)

Как видно из скриншотов - бакет поднялся и хранит в себе terrafom.state

---
![image](https://github.com/user-attachments/assets/73bc5afb-f25e-49dd-b4ab-e0bf679a1276)

Terraform более не просит подтверждать применение конфигурации, т.к. сравнивает передаваемый стейт со стейтом в бакете.

## Шаг 2 (Поднятие Kubernetes кластера)

Данный шаг выполнялся через Yandex Managed Service for Kubernetes

![image](https://github.com/user-attachments/assets/68d94bae-1769-4b4f-b979-ca2c4607fdd9)

```
kubectl get pods --all-namespaces
```
![image](https://github.com/user-attachments/assets/e0fa8110-1d18-48a0-a6a1-cf5e690eadbb)

```
nano ~/.kube/config
```
![image](https://github.com/user-attachments/assets/49fbc699-0535-4578-a5d8-f6a993654bda)

![image](https://github.com/user-attachments/assets/372e3ec7-d6fe-4bf6-9c1a-73f2d9123e5e)

![image](https://github.com/user-attachments/assets/05848a6b-aab9-4f87-9f6b-aa7d3dc97b94)

Как видно из скриншотов - пространства имен созданы и в конфиг добавлена корректная запись.

## Шаг 3 (Создание тестового приложения)

[Dockerfile](https://github.com/wintercomesX/yc-devops/blob/main/test-app/Dockerfile)

![image](https://github.com/user-attachments/assets/d4331679-5b5a-481d-8133-fbe68dbc0871)

В регестри созданы докерфайлы.

## Шаг 4 (Разворачиваем мониторинг и поднимаем сервис)

[Репозиторий с кодом](https://github.com/wintercomesX/yc-devops/tree/main/k8s-configs)

Мониторинг поднимался с помощью HELM.

![image](https://github.com/user-attachments/assets/68a579d1-c7eb-43c3-a8c9-ad786e44f04f)

Графана успешно открывается по 80 порту и отдает данные по кластеру кубера.

---

![image](https://github.com/user-attachments/assets/1377d13e-2b7c-4758-91dc-95d8f8ac939b)

Приложение успешно открывается по 80 порту и отдает корректную страницу.

## Шаг 5 (Настройка CI-CD)

В качестве CI-CD используется Github Actions. Просто и удобно.

![image](https://github.com/user-attachments/assets/993f66ac-98bb-42e0-8245-e2abeeb36946)

![image](https://github.com/user-attachments/assets/ed372e61-42ee-4388-9a2c-f2f456ceed5f)

![image](https://github.com/user-attachments/assets/35aac355-d20f-4aee-93bf-22955a4de200)

![image](https://github.com/user-attachments/assets/2db48cb3-a83a-4dbd-a042-baca8ddb53ee)

![image](https://github.com/user-attachments/assets/c357909b-bfac-46e2-be0f-3fe481631a4c)


Скриншоты показывают что пайплайн работает. Docker образ был задеплоен в кластер.








