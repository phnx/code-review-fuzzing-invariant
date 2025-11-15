; ModuleID = 'original_2.c'
source_filename = "original_2.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @second_max(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  %10 = load i32, ptr %4, align 4
  %11 = icmp ult i32 %10, 2
  br i1 %11, label %12, label %13

12:                                               ; preds = %2
  store i32 -2147483648, ptr %3, align 4
  br label %66

13:                                               ; preds = %2
  store i32 -2147483648, ptr %6, align 4
  store i32 -2147483648, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %14

14:                                               ; preds = %54, %13
  %15 = load i32, ptr %8, align 4
  %16 = load i32, ptr %4, align 4
  %17 = icmp ult i32 %15, %16
  br i1 %17, label %18, label %57

18:                                               ; preds = %14
  %19 = load ptr, ptr %5, align 8
  %20 = load i32, ptr %8, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %19, i64 %21
  %23 = load i32, ptr %22, align 4
  store i32 %23, ptr %9, align 4
  %24 = load i32, ptr %9, align 4
  %25 = load i32, ptr %6, align 4
  %26 = icmp sgt i32 %24, %25
  br i1 %26, label %27, label %29

27:                                               ; preds = %18
  %28 = load i32, ptr %6, align 4
  br label %43

29:                                               ; preds = %18
  %30 = load i32, ptr %9, align 4
  %31 = load i32, ptr %7, align 4
  %32 = icmp sgt i32 %30, %31
  br i1 %32, label %33, label %39

33:                                               ; preds = %29
  %34 = load i32, ptr %9, align 4
  %35 = load i32, ptr %6, align 4
  %36 = icmp slt i32 %34, %35
  br i1 %36, label %37, label %39

37:                                               ; preds = %33
  %38 = load i32, ptr %9, align 4
  br label %41

39:                                               ; preds = %33, %29
  %40 = load i32, ptr %7, align 4
  br label %41

41:                                               ; preds = %39, %37
  %42 = phi i32 [ %38, %37 ], [ %40, %39 ]
  br label %43

43:                                               ; preds = %41, %27
  %44 = phi i32 [ %28, %27 ], [ %42, %41 ]
  store i32 %44, ptr %7, align 4
  %45 = load i32, ptr %9, align 4
  %46 = load i32, ptr %6, align 4
  %47 = icmp sgt i32 %45, %46
  br i1 %47, label %48, label %50

48:                                               ; preds = %43
  %49 = load i32, ptr %9, align 4
  br label %52

50:                                               ; preds = %43
  %51 = load i32, ptr %6, align 4
  br label %52

52:                                               ; preds = %50, %48
  %53 = phi i32 [ %49, %48 ], [ %51, %50 ]
  store i32 %53, ptr %6, align 4
  call void asm sideeffect "nop", "~{dirflag},~{fpsr},~{flags}"() #1, !srcloc !6
  br label %54

54:                                               ; preds = %52
  %55 = load i32, ptr %8, align 4
  %56 = add nsw i32 %55, 1
  store i32 %56, ptr %8, align 4
  br label %14, !llvm.loop !7

57:                                               ; preds = %14
  %58 = load i32, ptr %7, align 4
  %59 = icmp eq i32 %58, -2147483648
  br i1 %59, label %60, label %62

60:                                               ; preds = %57
  %61 = load i32, ptr %6, align 4
  br label %64

62:                                               ; preds = %57
  %63 = load i32, ptr %7, align 4
  br label %64

64:                                               ; preds = %62, %60
  %65 = phi i32 [ %61, %60 ], [ %63, %62 ]
  store i32 %65, ptr %3, align 4
  br label %66

66:                                               ; preds = %64, %12
  %67 = load i32, ptr %3, align 4
  ret i32 %67
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 15.0.7"}
!6 = !{i64 372}
!7 = distinct !{!7, !8}
!8 = !{!"llvm.loop.mustprogress"}
