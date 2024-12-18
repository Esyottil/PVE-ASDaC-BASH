# #PROF39
<details>
  <summary><b>Предупреждение для пользователей Альт Сервер Виртуализации PVE!</b></summary>
  <br>
 В конце установки или удаления стендов скрипт перезагрузит сеть хоста для сохранения внесенных изменений (для создания/удаления виртуальных коммутаторов). Из-за бага, на Альт Сервер Виртуализации PVE все запущенные ранее машины потеряют коннект к своим бриджам! Это означает, что на всех ранее запущенных машинах сломается сеть и они не будут иметь сетевую связность!<br>
  Единственный способ это исправить - выключить и включить эти машины (не перезагрузка!), либо к каждой ВМ вручную переприменить сетевые настройки, дергая каждый интерфейс!
  <br><br>Так же есть еще один видимый баг - пропадают описания к сетевым интерфейсам (description). На самом деле, в самом конфиг файле интерфейсов описания не пропадают, просто PVE их не может корректно считать из-за того, что модуль-прокладка для etcnet добавляет свои доп. параметры в конфиг (а еще и по несколько раз) и родной модуль их не понимает. Костыльное решение - 1. применить сетевые настройки, если не применены. 2. зайти в файл /etc/network/interfaces, убрать дублирующиеся строки и настройку "HOST="
  
___
</details>

<br>

**Конфиг стенда для регионального чемпионата 09.02.06-2025 (модуль Б, варианты для ALT PVE и Proxmox VE версии 8+)**
```bash
b=testing_api sh=PVE-ASDaC-BASH.sh c='https://disk.yandex.ru/d/1-vlJJU_0mzefA';curl -sfOL "https://raw.githubusercontent.com/PavelAF/PVE-ASDaC-BASH/$b/$sh"&&{ chmod +x $sh&&./$sh -c "$c" -z -v;rm -f $sh;true;}||echo -e "\e[1;33m\nОшибка скачивания: проверьте подключение к Интернету, настройки DNS и URL адрес\ncurl exit code: $?\n\e[m">&2
```
**Пре-конфиг стендов демекзамена 09.02.06-2025, классический**
```bash
b=main sh=PVE-ASDaC-BASH.sh c='https://disk.yandex.ru/d/HDgvq-iMbduqag';curl -sfOL "https://raw.githubusercontent.com/PavelAF/PVE-ASDaC-BASH/$b/$sh"&&{ chmod +x $sh&&./$sh -c "$c" -z -v;rm -f $sh;true;}||echo -e "\e[1;33m\nОшибка скачивания: проверьте подключение к Интернету, настройки DNS и URL адрес\ncurl exit code: $?\n\e[m">&2
```
**Пре-конфиг стендов демекзамена 09.02.06-2025, только ОС Альт**
```bash
b=main sh=PVE-ASDaC-BASH.sh c='https://disk.yandex.ru/d/259h8afDR9hqyQ';curl -sfOL "https://raw.githubusercontent.com/PavelAF/PVE-ASDaC-BASH/$b/$sh"&&{ chmod +x $sh&&./$sh -c "$c" -z -v;rm -f $sh;true;}||echo -e "\e[1;33m\nОшибка скачивания: проверьте подключение к Интернету, настройки DNS и URL адрес\ncurl exit code: $?\n\e[m">&2
```
<br>
Скрипт простого авторазвертывания стендов с виртуальной ИТ-инфраструктурой на базе гипервизора Proxmox VE и Альт Сервер Виртуализация (PVE)

Поддерживаемые версии: Proxmox VE от 7 до 8.2 (8.3 - в ветке testing_api), Альт Сервер Виртуализация 10.0 и выше (PVE 7.0+)

Скрипт позволяет просто и быстро автоматизировать развертывание стедов для различных мероприятий (Чемпионаты "Профессионалы", демонстрационый экзамен, учебные стенды и пр.), управлять конфигурацией, создавать свои конфигурации авторазвертывания

**Более подробная информация о скрипте на страницах [вики](../../wiki)**

#### Быстрый старт:

1.  Открываем Proxmox, выбираем нужную Node и переходим в раздел
    “Shell”.
<img src="screenshots/2.png"/>
2. Для того, чтобы развернуть базовые стенды, скопируйте строку ниже и вставьте в консоль (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd> или ПКМ -> Вставить):

```
sh='PVE-ASDaC-BASH.sh';curl -sOL "https://raw.githubusercontent.com/PavelAF/PVE-ASDaC-BASH/main/$sh"&&chmod +x $sh&&./$sh -c https://disk.yandex.ru/d/HDgvq-iMbduqag -z;rm -f $sh
```

После нажатия <kbd>Enter</kbd> скрипт скачается и запустится

<img src="screenshots/6.png"/>

При запуске скрипта в терминале выведется конфигурация развертывания и выбор опций развертывания

По окончанию выполнения скрипта все испольуемые файлы удаляются автоматически
