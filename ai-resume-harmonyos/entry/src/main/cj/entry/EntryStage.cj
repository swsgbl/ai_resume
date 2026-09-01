// EntryStage.cj - 应用入口
package entry

import ohos.aafwk.ability.*
import ohos.aafwk.content.*
import ohos.bundle.*

public class EntryStage <: Ability {
    public func onStart(want: Want): Unit {
        super.onStart(want)
        println("[AI Resume] EntryStage started")
    }

    public func onActive(): Unit {
        super.onActive()
        println("[AI Resume] EntryStage active")
    }
}
